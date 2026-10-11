"""Real disposable ASP.NET HTTP acceptance; no DB or test framework replacement."""

import json
import os
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

fixture = Path(sys.argv[1])
assert fixture.exists(), "ASP.NET API acceptance fixture not implemented/built"
with socket.socket() as endpoint:
    endpoint.bind(("127.0.0.1", 0))
    port = endpoint.getsockname()[1]
base = f"http://127.0.0.1:{port}"
with tempfile.TemporaryFile(mode="w+") as log:
    process = subprocess.Popen(
        ["dotnet", str(fixture), "--urls", base],
        stdout=log,
        stderr=log,
        env={**os.environ, "ASPNETCORE_ENVIRONMENT": "Development"},
    )
    try:
        deadline = time.monotonic() + 30
        while True:
            if process.poll() is not None:
                log.seek(0)
                raise AssertionError("API exited: " + log.read())
            try:
                urllib.request.urlopen(base + "/health", timeout=1).close()
                break
            except (urllib.error.URLError, TimeoutError):
                if time.monotonic() >= deadline:
                    raise AssertionError("API startup deadline exceeded") from None
                time.sleep(0.1)

        def request(path, expected, body=None, method=None):
            data = None if body is None else json.dumps(body).encode()
            req = urllib.request.Request(
                base + path,
                data=data,
                method=method,
                headers={"Content-Type": "application/json"},
            )
            try:
                response = urllib.request.urlopen(req, timeout=3)
            except urllib.error.HTTPError as error:
                response = error
            with response:
                assert response.status == expected, (path, response.status, expected)
                content = response.read()
                return json.loads(content) if content else None

        assert request("/hello/Alice", 200) == {"greeting": "Hello, Alice!"}
        request("/hello/%20", 400)
        request("/items", 400, {"name": ""})
        created = request("/items", 201, {"name": "milk"})
        assert created["name"] == "milk"
        assert request("/items/" + str(created["id"]), 200) == created
        request("/items/" + str(created["id"]), 204, method="DELETE")
        request("/items/" + str(created["id"]), 404)
        print(
            "PASS: real ASP.NET HTTP health, greeting, validation, create/read/delete, not-found (8 scenarios)"
        )
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)

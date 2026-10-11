using System.Collections.Concurrent;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
var items = new ConcurrentDictionary<int, string>();
var sequence = 0;

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));
app.MapGet("/hello/{name}", (string name) =>
    string.IsNullOrWhiteSpace(name)
        ? Results.BadRequest()
        : Results.Ok(new { greeting = $"Hello, {name}!" }));
app.MapPost("/items", (ItemInput input) =>
{
    if (string.IsNullOrWhiteSpace(input.Name))
    {
        return Results.BadRequest();
    }

    var id = Interlocked.Increment(ref sequence);
    items[id] = input.Name;
    return Results.Created($"/items/{id}", new { id, name = input.Name });
});
app.MapGet("/items/{id:int}", (int id) =>
    items.TryGetValue(id, out var name)
        ? Results.Ok(new { id, name })
        : Results.NotFound());
app.MapDelete("/items/{id:int}", (int id) =>
    items.TryRemove(id, out _) ? Results.NoContent() : Results.NotFound());
app.Run();

internal sealed record ItemInput(string Name);

import delegator from '@RUNTIME@/lib/pi/node_modules/@mostlyworks/pi-delegator/src/index.ts';
import { boundedDelegate } from './policy.mjs';

// Keep the upstream dispatcher, schemas, cancellation and session cleanup.
// Only admission is narrowed; no second dispatcher or orchestration layer.
export default function (pi) {
  return delegator(new Proxy(pi, {
    get(target, key) {
      if (key === 'on') return (event, handler) => target.on(event, (data, ctx) => handler(data,
        event === 'session_start' ? new Proxy(ctx, {
          get(context, field) { return field === 'isProjectTrusted' ? () => false : Reflect.get(context, field); },
        }) : ctx));
      if (key === 'registerTool') return tool => target.registerTool({
        ...tool, execute: boundedDelegate(tool.execute),
      });
      return Reflect.get(target, key);
    },
  }));
}

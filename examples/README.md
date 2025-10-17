# CZMQ Ada Bindings - Examples

## Working Examples

### push_pull.adb - Recommended First Example
A single-process example demonstrating the PUSH-PULL pattern. This is the most reliable example to start with.

```bash
./push_pull
```

## Pub-Sub Examples (Timing Sensitive)

The publisher/subscriber pattern has a "slow joiner" syndrome where subscribers that connect after the publisher starts may miss early messages. This is a well-known ZeroMQ behavior, not a bug in the bindings.

### publisher.adb and subscriber.adb
Separate programs demonstrating pub-sub pattern.

**To run:**
1. Start subscriber first in one terminal:
   ```bash
   ./subscriber
   ```

2. Wait for "Ready to receive messages", then in another terminal:
   ```bash
   ./publisher
   ```

**Note:** Due to the slow joiner syndrome, messages may still be lost even with proper timing. For production use, consider:
- Using PUSH-PULL or REQ-REP patterns for reliable delivery
- Implementing application-level message acknowledgment
- Using a message broker pattern

### hello_world.adb
Single-process pub-sub example. May not work reliably due to slow joiner timing issues.

## Building

```bash
gprbuild -P examples.gpr
```

## Notes

- **IPC transport** (`ipc://`) works reliably in this environment
- **TCP transport** (`tcp://`) binding currently fails in the distrobox environment (ZMQ configuration issue)
- **Inproc transport** (`inproc://`) requires sockets to be in the same ZMQ context

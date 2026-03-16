# CZMQ Ada Bindings

High-level Ada bindings for CZMQ (ZeroMQ high-level C binding).

[!NOTE]
I'm new to Ada and want to learn it in depth by applying it to practical DevOps tasks. Since I couldn't find too many libraries for this space that are still maintained, I built this library. Community input (e.g. issues, pull requests) that helps my learning is always appreciated.

[!WARNING]
Until this library has reached a mature version 1.0, expect there to be breaking changes even with only minor version bumps.

## Features

- **Memory Safe**: Automatic resource cleanup using Ada controlled types
- **Type Safe**: Strong typing with Ada's type system
- **Modern Ada**: Uses Ada 2012 features (extended return statements)
- **Clean API**: High-level Ada interface hiding C complexity

## Project Structure

```
czmq_ada/
├── src/
│   ├── czmq.ads                 # Root package
│   ├── czmq-low_level.ads       # Thin C bindings
│   ├── czmq-sockets.ads/.adb    # High-level socket API
│   └── czmq-messages.ads/.adb   # High-level message API
├── examples/
│   ├── push_pull.adb            # PUSH-PULL pattern (recommended)
│   ├── publisher.adb            # PUB-SUB publisher
│   └── subscriber.adb           # PUB-SUB subscriber
├── czmq_ada.gpr                 # Main library project
└── examples/examples.gpr        # Examples project
```

## Building

### Prerequisites

- [Alire](https://alire.ada.dev/) package manager (provides the GNAT toolchain)
- CZMQ library and development headers

**Fedora/RHEL:**
```bash
sudo dnf install czmq-devel zeromq-devel
```

**Ubuntu/Debian:**
```bash
sudo apt install libczmq-dev
```

### Build Library

```bash
alr build
```

### Build and Run Tests

```bash
cd tests
alr build
bin/test_sockets
bin/test_certificates
bin/test_sockets_curve
bin/test_authentication
```

### Build Examples

```bash
cd examples
alr build
```

## API Overview

### Socket Types

```ada
type Socket_Type is (
   Pair, Pub, Sub, Req, Rep,
   Dealer, Router, Pull, Push,
   XPub, XSub, Stream
);
```

### Creating Sockets

```ada
--  Create socket without endpoint
Socket : Socket := New_Pub ("");

--  Or with endpoint (@ for bind, > for connect)
Socket : Socket := New_Pub ("@tcp://127.0.0.1:5555");
```

### Socket Operations

```ada
Bind (Socket, "tcp://*:5555");
Connect (Socket, "tcp://127.0.0.1:5555");
Unbind (Socket, "tcp://*:5555");
Disconnect (Socket, "tcp://127.0.0.1:5555");
```

### Messages

```ada
--  Create and send
Msg : Message := New_Message;
Add_String (Msg, "Hello");
Add_String (Msg, "World");
Send (Msg, Socket);  --  Consumes the message

--  Receive and read
Msg : Message := Receive (Socket);
Str : String := Pop_String (Msg);
Count : Natural := Size (Msg);
```

## Running Examples

### PUSH-PULL Pattern (Single Process)
```bash
examples/bin/push_pull
```

### PUB-SUB Pattern (Two Terminals)

**Terminal 1 - Publisher:**
```bash
examples/bin/publisher
```

**Terminal 2 - Subscriber:**
```bash
examples/bin/subscriber
```

[!NOTE]
The publisher waits 2 seconds before sending messages. This is necessary to avoid the "slow joiner syndrome" - a timing issue where initial messages may be lost during subscription establishment. See [Chapter 5 of the ZeroMQ Guide](https://zguide.zeromq.org/docs/chapter5/#toc3) for details.

## Current Limitations

- High-level wrappers for actors, pollers, and frames are not yet implemented
- PUB-SUB requires careful timing or synchronization

## Implementation Notes

### Subscription Filter Handling

When creating a SUB socket with an empty subscription filter (subscribe to all messages), it's critical to pass an actual empty C string `""` rather than `NULL`:

```ada
-- Correct: Always create C string for subscription
C_Subscribe := CS.New_String (Subscribe);  -- "" becomes empty C string

-- Wrong: Would pass NULL to C
if Subscribe /= "" then
   C_Subscribe := CS.New_String (Subscribe);
end if;
```

In C, an empty string `""` and `NULL` are different. CZMQ interprets:
- Empty string `""` = subscribe to all messages
- `NULL` = no subscription set (no messages received)

### Resource Management

All socket and message types use Ada's controlled types (`Limited_Controlled`) for automatic cleanup:

```ada
declare
   Socket : Socket := New_Pub ("@tcp://*:5555");
   Msg    : Message := New_Message;
begin
   -- Use socket and message
   -- Automatic cleanup when leaving scope
end;
```

Messages are consumed by `Send` - the handle is set to `null` after sending to prevent double-free.

## License

This project, like the underlying CZMQ library, is licensed under the Mozilla Public License 2.0 (MPL-2.0). See the [LICENSE](LICENSE) file for details.

## References

- [CZMQ Documentation](http://czmq.zeromq.org/)
- [ZeroMQ Guide](https://zguide.zeromq.org/)

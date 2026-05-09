--  CZMQ Ada Bindings - Signal Handling API
--
--  Provides a high-level Ada interface to CZMQ's interrupt detection
--  and signal handler management. CZMQ installs its own SIGINT/SIGTERM
--  handler during zsys_init (called when creating sockets), which
--  silently overrides GNAT.Ctrl_C. Use Is_Interrupted to detect
--  signals in CZMQ-based applications.
--
--  Copyright (c) 2026 Jochen Lillich <contact@geewiz.dev>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

package CZMQ.Signals is
   pragma Preelaborate;

   --  Check if a SIGINT or SIGTERM signal has been received.
   --  Returns True after CZMQ's signal handler fires.
   --  Use this instead of GNAT.Ctrl_C in CZMQ-based applications.
   function Is_Interrupted return Boolean;

   --  Handler procedure type for custom signal callbacks.
   --  Convention => C is required for compatibility with CZMQ's handler API.
   type Handler_Type is access procedure with Convention => C;

   --  Set a custom interrupt handler. This saves the default handlers
   --  so that Reset_Handler can restore them later. Calling multiple times
   --  replaces the previous custom handler. Passing null disables CZMQ's
   --  default SIGINT/SIGTERM handling entirely.
   procedure Set_Handler (Handler : Handler_Type);

   --  Restore the default interrupt handlers that were active before
   --  Set_Handler was called. Call this at exit if you used Set_Handler.
   procedure Reset_Handler;

end CZMQ.Signals;

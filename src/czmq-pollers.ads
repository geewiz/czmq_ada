--  CZMQ Ada Bindings - Poller API
--
--  Copyright (c) 2026 Jochen Lillich <contact@geewiz.dev>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Ada.Finalization;
with CZMQ.Low_Level;
with CZMQ.Sockets;
with System;

package CZMQ.Pollers is

   --  Managed poller type with automatic cleanup
   type Poller is new Ada.Finalization.Limited_Controlled with private;

   --  Create a new poller watching one socket
   function New_Poller (Socket : in out Sockets.Socket) return Poller;

   --  Add another socket to the poller
   procedure Add (Self : in out Poller; Socket : in out Sockets.Socket);

   --  Wait for any watched socket to become ready.
   --  Returns True if a socket is ready, False on timeout.
   --  After a True result, use Is_From to identify which socket fired.
   function Wait (Self : in out Poller; Timeout_Ms : Integer) return Boolean;

   --  Check whether the last Wait result came from a specific socket.
   --  Only meaningful after Wait returned True.
   function Is_From
     (Self   : Poller;
      Socket : Sockets.Socket) return Boolean;

   --  Check if poller is valid (has been created)
   function Is_Valid (Self : Poller) return Boolean;

private

   type Poller is new Ada.Finalization.Limited_Controlled with record
      Handle      : Low_Level.zpoller_t_Access := null;
      Last_Ready  : System.Address := System.Null_Address;
   end record;

   overriding procedure Finalize (Self : in out Poller);

end CZMQ.Pollers;

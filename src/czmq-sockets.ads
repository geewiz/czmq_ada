--  CZMQ Ada Bindings - Socket API
--
--  Copyright (c) 2025 Jochen Lillich <jochen@lillich.co>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Ada.Finalization;
with System;
with CZMQ.Low_Level;

package CZMQ.Sockets is

   type Socket_Type is (
      Pair,    -- Exclusive pair pattern
      Pub,     -- Publish pattern
      Sub,     -- Subscribe pattern
      Req,     -- Request pattern
      Rep,     -- Reply pattern
      Dealer,  -- Extended request pattern
      Router,  -- Extended reply pattern
      Pull,    -- Pull pattern
      Push,    -- Push pattern
      XPub,    -- Extended publish pattern
      XSub,    -- Extended subscribe pattern
      Stream   -- Stream pattern
   );

   --  Managed socket type with automatic cleanup
   type Socket is new Ada.Finalization.Limited_Controlled with private;

   --  Constructor-style functions
   function New_Socket (Kind : Socket_Type) return Socket;
   function New_Pub (Endpoint : String := "") return Socket;
   function New_Sub (Endpoint : String := ""; Subscribe : String := "") return Socket;
   function New_Req (Endpoint : String := "") return Socket;
   function New_Rep (Endpoint : String := "") return Socket;
   function New_Push (Endpoint : String := "") return Socket;
   function New_Pull (Endpoint : String := "") return Socket;
   function New_Dealer (Endpoint : String := "") return Socket;
   function New_Router (Endpoint : String := "") return Socket;

   --  Socket operations
   procedure Bind (Self : in out Socket; Endpoint : String);
   procedure Connect (Self : in out Socket; Endpoint : String);
   procedure Unbind (Self : in out Socket; Endpoint : String);
   procedure Disconnect (Self : in out Socket; Endpoint : String);
   procedure Set_Subscribe (Self : in out Socket; Filter : String);

   --  Check if socket is valid
   function Is_Valid (Self : Socket) return Boolean;

   --  Get access to the underlying C socket (for advanced usage)
   function Get_Handle (Self : Socket) return System.Address;

private

   use CZMQ.Low_Level;

   type Socket is new Ada.Finalization.Limited_Controlled with record
      Handle : zsock_t_Access := null;
   end record;

   overriding procedure Finalize (Self : in out Socket);

end CZMQ.Sockets;

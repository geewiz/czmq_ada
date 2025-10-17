--  CZMQ Ada Bindings - Message API
--
--  Copyright (c) 2025 Jochen Lillich <jochen@lillich.co>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Ada.Finalization;
with System;
with CZMQ.Low_Level;
with CZMQ.Sockets;

package CZMQ.Messages is

   --  Managed message type with automatic cleanup
   type Message is new Ada.Finalization.Limited_Controlled with private;

   --  Create a new empty message
   function New_Message return Message;

   --  Add a string frame to the message
   procedure Add_String (Self : in out Message; Data : String);

   --  Add raw binary data to the message
   procedure Add_Mem (Self : in out Message; Data : System.Address; Size : Natural);

   --  Pop a string frame from the message
   --  Returns empty string if no more frames
   function Pop_String (Self : in out Message) return String;

   --  Get the number of frames in the message
   function Size (Self : Message) return Natural;

   --  Send the message (consumes the message - it will be invalid after)
   procedure Send (Self : in out Message; Dest : in out Sockets.Socket);

   --  Receive a message from a socket
   function Receive (Source : in out Sockets.Socket) return Message;

   --  Check if message is valid
   function Is_Valid (Self : Message) return Boolean;

private

   use CZMQ.Low_Level;

   type Message is new Ada.Finalization.Limited_Controlled with record
      Handle : zmsg_t_Access := null;
   end record;

   overriding procedure Finalize (Self : in out Message);

end CZMQ.Messages;

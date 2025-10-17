--  Simple CZMQ Push-Pull example
--
--  Copyright (c) 2025 Jochen Lillich <jochen@lillich.co>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Ada.Text_IO;
with CZMQ.Sockets;
with CZMQ.Messages;

procedure Push_Pull is
   use Ada.Text_IO;
   use CZMQ.Sockets;
   use CZMQ.Messages;

   Pusher  : Socket := New_Push ("@tcp://127.0.0.1:5556");
   Puller  : Socket := New_Pull (">tcp://127.0.0.1:5556");

begin
   Put_Line ("CZMQ Ada Bindings - Push/Pull Example");
   Put_Line ("Pusher bound to tcp://127.0.0.1:5556");
   Put_Line ("Puller connected to tcp://127.0.0.1:5556");

   --  Give time for connection
   delay 0.1;

   --  Send a message
   declare
      Msg : Message := New_Message;
   begin
      Add_String (Msg, "Hello");
      Add_String (Msg, "from");
      Add_String (Msg, "CZMQ Ada!");
      Put_Line ("Sending message with" & Size (Msg)'Image & " frames...");
      Send (Msg, Pusher);
   end;

   --  Receive the message
   declare
      Msg : Message := Receive (Puller);
   begin
      Put_Line ("Received message with" & Size (Msg)'Image & " frames:");
      Put_Line ("  Frame 1: " & Pop_String (Msg));
      Put_Line ("  Frame 2: " & Pop_String (Msg));
      Put_Line ("  Frame 3: " & Pop_String (Msg));
   end;

   Put_Line ("Done!");

end Push_Pull;

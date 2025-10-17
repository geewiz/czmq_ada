--  CZMQ Subscriber Example
--
--  Copyright (c) 2025 Jochen Lillich <jochen@lillich.co>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Ada.Text_IO;
with CZMQ.Sockets;
with CZMQ.Messages;

procedure Subscriber is
   use Ada.Text_IO;
   use CZMQ.Sockets;
   use CZMQ.Messages;

   Sub : Socket := New_Sub (">tcp://127.0.0.1:5555", "");  --  Subscribe to all messages

begin
   Put_Line ("CZMQ Ada Subscriber");
   Put_Line ("Subscriber connected to tcp://127.0.0.1:5555");
   Put_Line ("Waiting for messages...");
   Put_Line ("");

   --  Receive messages in a loop
   for I in 1 .. 5 loop
      declare
         Msg : Message := Receive (Sub);
      begin
         Put_Line ("Received message with" & Size (Msg)'Image & " frames:");
         Put_Line ("  Frame 1: " & Pop_String (Msg));
         Put_Line ("  Frame 2: " & Pop_String (Msg));
         Put_Line ("");
      end;
   end loop;

   Put_Line ("Subscriber done!");

end Subscriber;

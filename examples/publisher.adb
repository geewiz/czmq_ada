--  CZMQ Publisher Example
--
--  Copyright (c) 2025 Jochen Lillich <jochen@lillich.co>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Ada.Text_IO;
with CZMQ.Sockets;
with CZMQ.Messages;

procedure Publisher is
   use Ada.Text_IO;
   use CZMQ.Sockets;
   use CZMQ.Messages;

   Pub : Socket := New_Pub ("@tcp://127.0.0.1:5555");

begin
   Put_Line ("CZMQ Ada Publisher");
   Put_Line ("Publisher bound to tcp://127.0.0.1:5555");

   --  Give time for subscribers to connect
   Put_Line ("Waiting 2 seconds for subscribers to connect...");
   delay 2.0;

   --  Send multiple messages
   for I in 1 .. 5 loop
      declare
         Msg : Message := New_Message;
      begin
         Add_String (Msg, "Message" & I'Image);
         Add_String (Msg, "from Publisher");
         Put_Line ("Sending message" & I'Image & "...");
         Send (Msg, Pub);
         delay 0.5;  --  Small delay between messages
      end;
   end loop;

   Put_Line ("Publisher done!");

end Publisher;

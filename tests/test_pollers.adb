--  Tests for CZMQ.Pollers high-level poller wrapper
--
--  Verifies poller creation, socket readiness detection, and timeout handling.
--  Feature test for https://github.com/geewiz/czmq_ada/issues/5

with Ada.Text_IO;
with CZMQ.Sockets;
with CZMQ.Messages;
with CZMQ.Pollers;

procedure Test_Pollers is

   use Ada.Text_IO;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Assert (Condition : Boolean; Description : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Description);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Description);
      end if;
   end Assert;

begin
   Put_Line ("=== CZMQ.Pollers Tests ===");
   Put_Line ("");

   --  Test 1: New_Poller creates a valid poller
   Put_Line ("-- New_Poller lifecycle --");
   declare
      Sock   : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pull;
      Poller : CZMQ.Pollers.Poller := CZMQ.Pollers.New_Poller (Sock);
   begin
      Assert (Poller.Is_Valid, "New_Poller creates a valid poller");
   end;

   Put_Line ("");

   --  Test 2: Wait returns False on timeout
   Put_Line ("-- Wait with timeout --");
   declare
      Sock   : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pull;
      Poller : CZMQ.Pollers.Poller := CZMQ.Pollers.New_Poller (Sock);
   begin
      Sock.Bind ("inproc://test-pollers-timeout");
      Assert (not Poller.Wait (50), "Wait returns False on timeout");
   end;

   Put_Line ("");

   --  Test 3: Wait returns True when socket is ready, Is_From identifies it
   Put_Line ("-- Wait with ready socket --");
   declare
      Pusher : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Push;
      Puller : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pull;
      Poller : CZMQ.Pollers.Poller := CZMQ.Pollers.New_Poller (Puller);
      Msg    : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
   begin
      Pusher.Bind ("inproc://test-pollers-ready");
      Puller.Connect ("inproc://test-pollers-ready");
      delay 0.05;

      Msg.Add_String ("test");
      Msg.Send (Pusher);

      Assert (Poller.Wait (1000), "Wait returns True when message available");
      Assert (Poller.Is_From (Puller), "Is_From identifies the ready socket");
   end;

   Put_Line ("");

   --  Test 4: Multi-socket poller with Add
   Put_Line ("-- Multi-socket poller --");
   declare
      Pusher  : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Push;
      Puller1 : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pull;
      Puller2 : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pull;
      Poller  : CZMQ.Pollers.Poller := CZMQ.Pollers.New_Poller (Puller1);
      Msg     : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
   begin
      Puller1.Bind ("inproc://test-pollers-multi1");
      Puller2.Bind ("inproc://test-pollers-multi2");
      Pusher.Connect ("inproc://test-pollers-multi2");
      Poller.Add (Puller2);
      delay 0.05;

      Msg.Add_String ("to-puller2");
      Msg.Send (Pusher);

      Assert (Poller.Wait (1000), "Wait returns True on multi-socket poller");
      Assert (not Poller.Is_From (Puller1),
              "Is_From correctly rejects non-ready socket");
      Assert (Poller.Is_From (Puller2),
              "Is_From correctly identifies ready socket");
   end;

   Put_Line ("");

   --  Test 5: Wait on invalid poller raises CZMQ_Error
   Put_Line ("-- Error handling --");
   declare
      Poller : CZMQ.Pollers.Poller;
   begin
      if Poller.Wait (50) then
         Assert (False, "Wait on invalid poller should raise CZMQ_Error");
      else
         Assert (False, "Wait on invalid poller should raise CZMQ_Error");
      end if;
   exception
      when CZMQ.CZMQ_Error =>
         Assert (True, "Wait on invalid poller raises CZMQ_Error");
   end;

   Put_Line ("");

   --  Summary
   Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
             Natural'Image (Fail_Count) & " failed ===");

   if Fail_Count > 0 then
      raise Program_Error with "Test failures detected";
   end if;
end Test_Pollers;

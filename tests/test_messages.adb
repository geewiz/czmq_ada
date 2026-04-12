--  Tests for CZMQ.Messages receive with timeout
--
--  Verifies that Receive returns a status distinguishing success from timeout.
--  Regression test for https://github.com/geewiz/czmq_ada/issues/3

with Ada.Text_IO;
with CZMQ.Sockets;
with CZMQ.Messages;

procedure Test_Messages is

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
   Put_Line ("=== CZMQ.Messages Receive Tests ===");
   Put_Line ("");

   --  Test 1: Receive succeeds when a message is available
   Put_Line ("-- Receive with available message --");
   declare
      Pusher : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Push;
      Puller : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pull;
      Msg_Out : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
      Msg_In  : CZMQ.Messages.Message;
      Status  : CZMQ.Messages.Receive_Status;
      use type CZMQ.Messages.Receive_Status;
   begin
      Pusher.Bind ("inproc://test-recv-ok");
      Puller.Connect ("inproc://test-recv-ok");
      delay 0.05;

      Msg_Out.Add_String ("hello");
      Msg_Out.Send (Pusher);

      --  Set a short timeout so the test doesn't hang if something goes wrong
      Puller.Set_Receive_Timeout (1000);

      CZMQ.Messages.Receive (Puller, Msg_In, Status);
      Assert (Status = CZMQ.Messages.Success,
              "Receive returns Success when message available");
      Assert (Msg_In.Is_Valid,
              "Message is valid after successful receive");
      Assert (Msg_In.Pop_String = "hello",
              "Message content matches what was sent");
   end;

   Put_Line ("");

   --  Test 2: Receive returns Timeout when rcvtimeo expires
   Put_Line ("-- Receive with timeout --");
   declare
      Puller : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pull;
      Msg_In : CZMQ.Messages.Message;
      Status : CZMQ.Messages.Receive_Status;
      use type CZMQ.Messages.Receive_Status;
   begin
      Puller.Bind ("inproc://test-recv-timeout");

      --  Set a very short receive timeout
      Puller.Set_Receive_Timeout (50);

      CZMQ.Messages.Receive (Puller, Msg_In, Status);
      Assert (Status = CZMQ.Messages.Timeout,
              "Receive returns Timeout when no message arrives");
      Assert (not Msg_In.Is_Valid,
              "Message is invalid after timeout");
   end;

   Put_Line ("");

   --  Test 3: Receive on invalid socket raises CZMQ_Error
   Put_Line ("-- Receive on invalid socket --");
   declare
      Bad_Sock : CZMQ.Sockets.Socket;
      Msg_In   : CZMQ.Messages.Message;
      Status   : CZMQ.Messages.Receive_Status;
   begin
      CZMQ.Messages.Receive (Bad_Sock, Msg_In, Status);
      Assert (False, "Receive on invalid socket should raise CZMQ_Error");
   exception
      when CZMQ.CZMQ_Error =>
         Assert (True, "Receive on invalid socket raises CZMQ_Error");
   end;

   Put_Line ("");

   --  Summary
   Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
             Natural'Image (Fail_Count) & " failed ===");

   if Fail_Count > 0 then
      raise Program_Error with "Test failures detected";
   end if;
end Test_Messages;

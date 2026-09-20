--  Tests for CZMQ.Messages receive and send outcomes
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
   Put_Line ("=== CZMQ.Messages Tests ===");
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

   --  Test 4: Mandatory ROUTER sends to a connected DEALER
   Put_Line ("-- Mandatory ROUTER send to identified DEALER --");
   declare
      Router         : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Router;
      Dealer         : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Dealer;
      Ready_Out      : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
      Ready_In       : CZMQ.Messages.Message;
      Ready_Status   : CZMQ.Messages.Receive_Status;
      Send_Result    : CZMQ.Messages.Send_Status;
      Received       : CZMQ.Messages.Message;
      Receive_Status : CZMQ.Messages.Receive_Status;
      use type CZMQ.Messages.Receive_Status;
      use type CZMQ.Messages.Send_Status;
   begin
      Router.Set_Router_Mandatory;
      Router.Bind ("inproc://issue-19-enqueued");
      Dealer.Set_Identity ("issue-19-dealer");
      Dealer.Connect ("inproc://issue-19-enqueued");

      Ready_Out.Add_String ("issue-19-ready");
      Ready_Out.Send (Dealer);
      Router.Set_Receive_Timeout (1000);
      CZMQ.Messages.Receive (Router, Ready_In, Ready_Status);

      Assert (Ready_Status = CZMQ.Messages.Success,
              "ROUTER receives the DEALER ready message");
      Assert (Ready_In.Size = 2,
              "ROUTER receives identity and ready frames");

      declare
         Route    : constant String := Ready_In.Pop_String;
         Outgoing : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
      begin
         Assert (Route = "issue-19-dealer",
                 "ROUTER learns the DEALER identity from the handshake");
         Assert (Ready_In.Pop_String = "issue-19-ready",
                 "ROUTER receives the ready payload");

         Outgoing.Add_String (Route);
         Outgoing.Add_String ("issue-19-enqueued-payload");
         Outgoing.Send (Router, Send_Result);
         Assert (Send_Result = CZMQ.Messages.Enqueued,
                 "Mandatory ROUTER reports Enqueued for a known route");
         Assert (not Outgoing.Is_Valid,
                 "Enqueued send consumes the outgoing message");

         Dealer.Set_Receive_Timeout (1000);
         CZMQ.Messages.Receive (Dealer, Received, Receive_Status);
         Assert (Receive_Status = CZMQ.Messages.Success,
                 "DEALER receives the routed message");
         Assert (Received.Size = 1,
                 "DEALER receives only the payload frame");
         Assert (Received.Pop_String = "issue-19-enqueued-payload",
                 "DEALER receives the exact routed payload");
      end;
   end;

   Put_Line ("");

   --  Test 5: The existing two-argument Send reaches a known DEALER
   Put_Line ("-- Existing Send to identified DEALER --");
   declare
      Router         : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Router;
      Dealer         : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Dealer;
      Ready_Out      : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
      Ready_In       : CZMQ.Messages.Message;
      Ready_Status   : CZMQ.Messages.Receive_Status;
      Received       : CZMQ.Messages.Message;
      Receive_Status : CZMQ.Messages.Receive_Status;
      use type CZMQ.Messages.Receive_Status;
   begin
      Router.Set_Router_Mandatory;
      Router.Bind ("inproc://issue-19-legacy-known-route");
      Dealer.Set_Identity ("issue-19-legacy-route-dealer");
      Dealer.Connect ("inproc://issue-19-legacy-known-route");

      Ready_Out.Add_String ("issue-19-ready");
      Ready_Out.Send (Dealer);
      Router.Set_Receive_Timeout (1000);
      CZMQ.Messages.Receive (Router, Ready_In, Ready_Status);
      Assert (Ready_Status = CZMQ.Messages.Success,
              "ROUTER receives the DEALER ready message for existing Send");

      declare
         Route    : constant String := Ready_In.Pop_String;
         Outgoing : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
      begin
         Assert (Route = "issue-19-legacy-route-dealer",
                 "Existing Send learns the DEALER identity from the handshake");
         Assert (Ready_In.Pop_String = "issue-19-ready",
                 "Existing Send receives the ready payload");

         Outgoing.Add_String (Route);
         Outgoing.Add_String ("issue-19-legacy-known-payload");
         Outgoing.Send (Router);
      end;

      Dealer.Set_Receive_Timeout (1000);
      CZMQ.Messages.Receive (Dealer, Received, Receive_Status);
      Assert (Receive_Status = CZMQ.Messages.Success,
              "DEALER receives the message sent with existing Send");
      Assert (Received.Size = 1,
              "Existing Send delivers only the payload frame");
      Assert (Received.Pop_String = "issue-19-legacy-known-payload",
              "Existing Send delivers the exact payload");
   end;

   Put_Line ("");

   --  Test 6: Mandatory ROUTER reports an unknown identity as unroutable
   Put_Line ("-- Mandatory ROUTER unknown identity --");
   declare
      Router       : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Router;
      Dealer       : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Dealer;
      Ready_Out    : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
      Ready_In     : CZMQ.Messages.Message;
      Ready_Status : CZMQ.Messages.Receive_Status;
      Unknown      : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
      Send_Result  : CZMQ.Messages.Send_Status;
      use type CZMQ.Messages.Receive_Status;
      use type CZMQ.Messages.Send_Status;
   begin
      Router.Set_Router_Mandatory;
      Router.Bind ("inproc://issue-19-unroutable");
      Dealer.Set_Identity ("issue-19-known-dealer");
      Dealer.Connect ("inproc://issue-19-unroutable");

      Ready_Out.Add_String ("issue-19-ready");
      Ready_Out.Send (Dealer);
      Router.Set_Receive_Timeout (1000);
      CZMQ.Messages.Receive (Router, Ready_In, Ready_Status);
      Assert (Ready_Status = CZMQ.Messages.Success,
              "ROUTER establishes a known peer before the unknown route");
      Assert (Ready_In.Pop_String = "issue-19-known-dealer",
              "ROUTER receives the known peer identity");
      Assert (Ready_In.Pop_String = "issue-19-ready",
              "ROUTER receives the known peer ready payload");

      Unknown.Add_String ("issue-19-missing-dealer");
      Unknown.Add_String ("issue-19-unroutable-payload");
      Unknown.Send (Router, Send_Result);
      Assert (Send_Result = CZMQ.Messages.Unroutable,
              "Mandatory ROUTER reports Unroutable for an unknown identity");
      Assert (Unknown.Is_Valid,
              "Unroutable send leaves the message valid");
      Assert (Unknown.Size = 2,
              "Unroutable send leaves both routing frames observable");
      Assert (Unknown.Pop_String = "issue-19-missing-dealer",
              "Unroutable send preserves the route frame");
      Assert (Unknown.Pop_String = "issue-19-unroutable-payload",
              "Unroutable send preserves the payload frame");
   end;

   Put_Line ("");

   --  Test 7: A no-peer send with an immediate timeout is an error
   Put_Line ("-- No-peer immediate-timeout send --");
   declare
      Dealer      : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Dealer;
      Msg         : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
      Send_Result : CZMQ.Messages.Send_Status;
   begin
      Dealer.Set_Send_Timeout (0);
      Msg.Add_String ("issue-19-no-peer-payload");

      begin
         Msg.Send (Dealer, Send_Result);
         Assert (False,
                 "No-peer immediate-timeout send should raise CZMQ_Error");
      exception
         when CZMQ.CZMQ_Error =>
            Assert (True,
                    "No-peer immediate-timeout send raises CZMQ_Error");
      end;
   end;

   Put_Line ("");

   --  Test 8: The existing two-argument Send raises on an unknown route
   Put_Line ("-- Existing Send on mandatory ROUTER unknown identity --");
   declare
      Router       : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Router;
      Dealer       : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Dealer;
      Ready_Out    : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
      Ready_In     : CZMQ.Messages.Message;
      Ready_Status : CZMQ.Messages.Receive_Status;
      Unknown      : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
      use type CZMQ.Messages.Receive_Status;
   begin
      Router.Set_Router_Mandatory;
      Router.Bind ("inproc://issue-19-legacy-send");
      Dealer.Set_Identity ("issue-19-legacy-known-dealer");
      Dealer.Connect ("inproc://issue-19-legacy-send");

      Ready_Out.Add_String ("issue-19-ready");
      Ready_Out.Send (Dealer);
      Router.Set_Receive_Timeout (1000);
      CZMQ.Messages.Receive (Router, Ready_In, Ready_Status);
      Assert (Ready_Status = CZMQ.Messages.Success,
              "ROUTER establishes a peer for the existing Send test");
      Assert (Ready_In.Pop_String = "issue-19-legacy-known-dealer",
              "Existing Send test receives the known peer identity");
      Assert (Ready_In.Pop_String = "issue-19-ready",
              "Existing Send test receives the ready payload");

      Unknown.Add_String ("issue-19-legacy-missing-dealer");
      Unknown.Add_String ("issue-19-legacy-payload");
      begin
         Unknown.Send (Router);
         Assert (False,
                 "Existing two-argument Send should raise on unknown route");
      exception
         when CZMQ.CZMQ_Error =>
            Assert (True,
                    "Existing two-argument Send raises on unknown route");
      end;
   end;

   Put_Line ("");

   --  Test 9: A default ROUTER silently discards an unknown route
   Put_Line ("-- Default ROUTER unknown identity --");
   declare
      Router  : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Router;
      Unknown : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
   begin
      Router.Bind ("inproc://issue-19-default-discard");

      Unknown.Add_String ("issue-19-default-missing-dealer");
      Unknown.Add_String ("issue-19-default-discard-payload");
      begin
         Unknown.Send (Router);
         Assert (True,
                 "Default ROUTER silently discards an unknown identity");
         Assert (not Unknown.Is_Valid,
                 "Default ROUTER unknown-route send consumes the message");
      exception
         when CZMQ.CZMQ_Error =>
            Assert (False,
                    "Default ROUTER unknown identity should not raise");
      end;
   end;

   --  Summary
   Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
             Natural'Image (Fail_Count) & " failed ===");

   if Fail_Count > 0 then
      raise Program_Error with "Test failures detected";
   end if;
end Test_Messages;

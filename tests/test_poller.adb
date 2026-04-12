--  Tests for zpoller low-level binding
--
--  Verifies that zpoller_new correctly creates a poller without crashing.
--  Regression test for https://github.com/geewiz/czmq_ada/issues/2

with Ada.Text_IO;
with System;
with Interfaces.C;
with CZMQ.Low_Level;
with CZMQ.Sockets;

procedure Test_Poller is

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
   Put_Line ("=== zpoller Low-Level Tests ===");
   Put_Line ("");

   --  Test 1: Create a poller with one socket and poll with short timeout
   Put_Line ("-- zpoller_new with NULL terminator --");
   declare
      Sock    : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Router;
      Poller  : aliased CZMQ.Low_Level.zpoller_t_Access;
      Ready   : System.Address;
      use type CZMQ.Low_Level.zpoller_t_Access;
      use type System.Address;
   begin
      Sock.Bind ("inproc://test-poller");

      Poller := CZMQ.Low_Level.zpoller_new
        (Sock.Get_Handle, System.Null_Address);
      Assert (Poller /= null, "zpoller_new returns non-null poller");

      --  Poll with 10ms timeout — no messages expected, should return
      --  Null_Address without crashing
      Ready := CZMQ.Low_Level.zpoller_wait (Poller, 10);
      Assert (Ready = System.Null_Address,
              "zpoller_wait returns null on timeout");

      CZMQ.Low_Level.zpoller_destroy (Poller'Access);
      Assert (Poller = null, "zpoller_destroy sets pointer to null");
   end;

   Put_Line ("");

   --  Test 2: Create a poller and add a second socket
   Put_Line ("-- zpoller_add after creation --");
   declare
      Sock1   : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Router;
      Sock2   : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Dealer;
      Poller  : aliased CZMQ.Low_Level.zpoller_t_Access;
      Rc      : Interfaces.C.int;
      use type CZMQ.Low_Level.zpoller_t_Access;
      use type Interfaces.C.int;
   begin
      Sock1.Bind ("inproc://test-poller-add");
      Sock2.Connect ("inproc://test-poller-add");

      Poller := CZMQ.Low_Level.zpoller_new
        (Sock1.Get_Handle, System.Null_Address);
      Assert (Poller /= null, "zpoller_new returns non-null poller");

      Rc := CZMQ.Low_Level.zpoller_add (Poller, Sock2.Get_Handle);
      Assert (Rc = 0, "zpoller_add succeeds");

      CZMQ.Low_Level.zpoller_destroy (Poller'Access);
   end;

   Put_Line ("");

   --  Summary
   Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
             Natural'Image (Fail_Count) & " failed ===");

   if Fail_Count > 0 then
      raise Program_Error with "Test failures detected";
   end if;
end Test_Poller;

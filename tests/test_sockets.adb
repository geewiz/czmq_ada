--  Tests for CZMQ.Sockets general socket options
--
--  Tests setting socket identity and other general options.

with Ada.Text_IO;
with System;
with CZMQ.Sockets;

procedure Test_Sockets is

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
   Put_Line ("=== CZMQ.Sockets General Tests ===");
   Put_Line ("");

   --  Test 1: Set identity on DEALER socket
   Put_Line ("-- Socket identity on DEALER --");
   declare
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Dealer;
   begin
      Sock.Set_Identity ("worker-1");
      Assert (True, "Set_Identity succeeds on DEALER socket");
   end;

   Put_Line ("");

   --  Test 2: Set identity on ROUTER socket
   Put_Line ("-- Socket identity on ROUTER --");
   declare
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Router;
   begin
      Sock.Set_Identity ("router-1");
      Assert (True, "Set_Identity succeeds on ROUTER socket");
   end;

   Put_Line ("");

   --  Test 3: Set identity on REQ socket
   Put_Line ("-- Socket identity on REQ --");
   declare
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Req;
   begin
      Sock.Set_Identity ("client-1");
      Assert (True, "Set_Identity succeeds on REQ socket");
   end;

   Put_Line ("");

   --  Test 4: Get_Handle returns non-null address for valid socket
   Put_Line ("-- Get_Handle on valid socket --");
   declare
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Dealer;
      Addr : System.Address;
      use type System.Address;
   begin
      Addr := Sock.Get_Handle;
      Assert (Addr /= System.Null_Address,
              "Get_Handle returns non-null address for valid socket");
   end;

   Put_Line ("");

   --  Test 5: Get_Handle returns Null_Address for invalid socket
   Put_Line ("-- Get_Handle on invalid socket --");
   declare
      Sock : CZMQ.Sockets.Socket;
      Addr : System.Address;
      use type System.Address;
   begin
      Addr := Sock.Get_Handle;
      Assert (Addr = System.Null_Address,
              "Get_Handle returns Null_Address for invalid socket");
   end;

   Put_Line ("");

   --  Test 6: Set and get receive timeout
   Put_Line ("-- Receive timeout --");
   declare
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pull;
   begin
      Sock.Set_Receive_Timeout (500);
      Assert (Sock.Receive_Timeout = 500,
              "Receive_Timeout returns value set by Set_Receive_Timeout");
   end;

   Put_Line ("");

   --  Test 7: Set and get send timeout
   Put_Line ("-- Send timeout --");
   declare
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Push;
   begin
      Sock.Set_Send_Timeout (250);
      Assert (Sock.Send_Timeout = 250,
              "Send_Timeout returns value set by Set_Send_Timeout");
   end;

   Put_Line ("");

   --  Test 8: Default timeout is -1 (infinite)
   Put_Line ("-- Default timeout --");
   declare
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pull;
   begin
      Assert (Sock.Receive_Timeout = -1,
              "Default Receive_Timeout is -1 (infinite)");
      Assert (Sock.Send_Timeout = -1,
              "Default Send_Timeout is -1 (infinite)");
   end;

   Put_Line ("");

   --  Test 9: Timeout on invalid socket raises CZMQ_Error
   Put_Line ("-- Timeout on invalid socket --");
   declare
      Sock : CZMQ.Sockets.Socket;
   begin
      Sock.Set_Receive_Timeout (100);
      Assert (False, "Set_Receive_Timeout on invalid socket should raise");
   exception
      when CZMQ.CZMQ_Error =>
         Assert (True, "Set_Receive_Timeout on invalid socket raises CZMQ_Error");
   end;

   Put_Line ("");

   --  Test 10: Invalid socket raises CZMQ_Error
   Put_Line ("-- Error handling --");
   declare
      Sock : CZMQ.Sockets.Socket;  --  default, invalid
   begin
      Sock.Set_Identity ("should-fail");
      Assert (False, "Set_Identity on invalid socket should raise");
   exception
      when CZMQ.CZMQ_Error =>
         Assert (True, "Set_Identity on invalid socket raises CZMQ_Error");
   end;

   Put_Line ("");

    Put_Line ("");

    --  Test 11: Open/Close happy path
    Put_Line ("-- Open/Close happy path --");
    declare
       Sock : CZMQ.Sockets.Socket;  --  Default empty
    begin
       Assert (not Sock.Is_Valid, "Default socket is not valid");
       Sock.Open_Pub;
       Assert (Sock.Is_Valid, "Open_Pub makes socket valid");
       Sock.Close;
       Assert (not Sock.Is_Valid, "Close makes socket invalid");
    end;

    Put_Line ("");

    --  Test 12: Open on already-open socket raises Program_Error
    Put_Line ("-- Open on already-open socket --");
    declare
       Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pub;
    begin
       Sock.Open_Req;
       Assert (False, "Open on already-open socket should raise Program_Error");
    exception
       when Program_Error =>
          Assert (True, "Open on already-open socket raises Program_Error");
    end;

    Put_Line ("");

    --  Test 13: Close on already-closed socket is no-op
    Put_Line ("-- Close idempotent --");
    declare
       Sock : CZMQ.Sockets.Socket;
    begin
       Sock.Close;  --  Should not raise
       Assert (True, "Close on already-closed socket is no-op");
    end;

    Put_Line ("");

    --  Test 14: Open creates bare socket
    Put_Line ("-- Open bare socket --");
    declare
       Sock : CZMQ.Sockets.Socket;
    begin
       Sock.Open (CZMQ.Sockets.Dealer);
       Assert (Sock.Is_Valid, "Open creates bare socket");
       Sock.Close;
    end;

    Put_Line ("");

    --  Test 15: Operation on closed socket raises CZMQ_Error
    Put_Line ("-- Operation on closed socket --");
    declare
       Sock : CZMQ.Sockets.Socket;
    begin
       Sock.Open_Pub;
       Sock.Close;
       Sock.Set_Identity ("test");
       Assert (False, "Set_Identity on closed socket should raise");
    exception
       when CZMQ.CZMQ_Error =>
          Assert (True, "Set_Identity on closed socket raises CZMQ_Error");
    end;

    Put_Line ("");

    --  Test 16: Constructors still work after refactor
    Put_Line ("-- Constructors still work --");
    declare
       Pub_Sock  : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pub;
       Sub_Sock  : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Sub;
       Req_Sock  : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Req;
       Rep_Sock  : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Rep;
       Push_Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Push;
       Pull_Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Pull;
       Deal_Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Dealer;
       Rout_Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Router;
    begin
       Assert (Pub_Sock.Is_Valid, "New_Pub still works");
       Assert (Sub_Sock.Is_Valid, "New_Sub still works");
       Assert (Req_Sock.Is_Valid, "New_Req still works");
       Assert (Rep_Sock.Is_Valid, "New_Rep still works");
       Assert (Push_Sock.Is_Valid, "New_Push still works");
       Assert (Pull_Sock.Is_Valid, "New_Pull still works");
       Assert (Deal_Sock.Is_Valid, "New_Dealer still works");
       Assert (Rout_Sock.Is_Valid, "New_Router still works");
    end;

    Put_Line ("");

    --  Test 17: Open_Sub with empty Subscribe filter
    Put_Line ("-- Open_Sub with empty filter --");
    declare
       Sock : CZMQ.Sockets.Socket;
    begin
       Sock.Open_Sub;  --  Empty endpoint and subscribe
       Assert (Sock.Is_Valid, "Open_Sub with empty filter creates valid socket");
       Sock.Close;
    end;

    Put_Line ("");

    --  Summary
    Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
              Natural'Image (Fail_Count) & " failed ===");

    if Fail_Count > 0 then
       raise Program_Error with "Test failures detected";
    end if;
end Test_Sockets;

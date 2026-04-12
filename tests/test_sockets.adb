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

   --  Test 6: Invalid socket raises CZMQ_Error
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

   --  Summary
   Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
             Natural'Image (Fail_Count) & " failed ===");

   if Fail_Count > 0 then
      raise Program_Error with "Test failures detected";
   end if;
end Test_Sockets;

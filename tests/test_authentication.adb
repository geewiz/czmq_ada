--  Tests for CZMQ.Authentication
--
--  Tests the ZAP authenticator lifecycle, CURVE-encrypted communication
--  with authentication, and PLAIN authentication.

with Ada.Text_IO;
with Ada.Directories;
with CZMQ.Authentication;
with CZMQ.Certificates;
with CZMQ.Messages;
with CZMQ.Sockets;

procedure Test_Authentication is

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
   Put_Line ("=== CZMQ.Authentication Tests ===");
   Put_Line ("");

   --  Test 1: Create and destroy authenticator
   Put_Line ("-- Authenticator lifecycle --");
   declare
      Auth : CZMQ.Authentication.Authenticator :=
        CZMQ.Authentication.New_Authenticator;
   begin
      Assert (Auth.Is_Valid, "New authenticator is valid");
   end;
   --  Finalize should have destroyed it without error
   Assert (True, "Authenticator destroyed cleanly via finalization");

   Put_Line ("");

   --  Test 2: Verbose mode
   Put_Line ("-- Verbose mode --");
   declare
      Auth : CZMQ.Authentication.Authenticator :=
        CZMQ.Authentication.New_Authenticator;
   begin
      Auth.Set_Verbose;
      Assert (True, "Set_Verbose succeeds");
   end;

   Put_Line ("");

   --  Test 3: IP allow/deny
   Put_Line ("-- IP allow/deny --");
   declare
      Auth : CZMQ.Authentication.Authenticator :=
        CZMQ.Authentication.New_Authenticator;
   begin
      Auth.Allow ("127.0.0.1");
      Assert (True, "Allow IP address succeeds");

      Auth.Deny ("192.168.0.1");
      Assert (True, "Deny IP address succeeds");
   end;

   Put_Line ("");

   --  Test 4: Configure CURVE with allow-any
   Put_Line ("-- CURVE allow-any --");
   declare
      Auth : CZMQ.Authentication.Authenticator :=
        CZMQ.Authentication.New_Authenticator;
   begin
      Auth.Allow_Any_Curve;
      Assert (True, "Allow_Any_Curve succeeds");
   end;

   Put_Line ("");

   --  Test 5: Configure CURVE with certificate directory
   Put_Line ("-- CURVE certificate directory --");
   declare
      Cert_Dir : constant String := "test_auth_certs_tmp";
      Auth : CZMQ.Authentication.Authenticator :=
        CZMQ.Authentication.New_Authenticator;
      Client_Cert : CZMQ.Certificates.Certificate :=
        CZMQ.Certificates.New_Certificate;
   begin
      --  Create cert directory and save a client public key there
      if not Ada.Directories.Exists (Cert_Dir) then
         Ada.Directories.Create_Directory (Cert_Dir);
      end if;

      Client_Cert.Save_Public (Cert_Dir & "/client");

      Auth.Configure_Curve (Cert_Dir);
      Assert (True, "Configure_Curve with directory succeeds");

      --  Clean up
      Ada.Directories.Delete_File (Cert_Dir & "/client");
      Ada.Directories.Delete_Directory (Cert_Dir);
   end;

   Put_Line ("");

   --  Test 6: CURVE encrypted end-to-end communication
   Put_Line ("-- CURVE end-to-end --");
   declare
      Auth : CZMQ.Authentication.Authenticator :=
        CZMQ.Authentication.New_Authenticator;

      Server_Cert : CZMQ.Certificates.Certificate :=
        CZMQ.Certificates.New_Certificate;
      Client_Cert : CZMQ.Certificates.Certificate :=
        CZMQ.Certificates.New_Certificate;

      Server : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Socket (CZMQ.Sockets.Rep);
      Client : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Socket (CZMQ.Sockets.Req);
   begin
      --  Allow any CURVE client for this test
      Auth.Allow_Any_Curve;

      --  Configure server: apply server cert, enable CURVE server mode
      Server_Cert.Apply (Server);
      Server.Set_Curve_Server;
      Server.Bind ("tcp://127.0.0.1:9500");

      --  Configure client: apply client cert, set server's public key
      Client_Cert.Apply (Client);
      Client.Set_Curve_Serverkey (Server_Cert.Public_Key);
      Client.Connect ("tcp://127.0.0.1:9500");

      --  Exchange a message
      declare
         Msg_Out : CZMQ.Messages.Message := CZMQ.Messages.New_Message;
      begin
         Msg_Out.Add_String ("hello encrypted");
         Msg_Out.Send (Client);
      end;

      declare
         Msg_In : CZMQ.Messages.Message := CZMQ.Messages.Receive (Server);
         Payload : constant String := Msg_In.Pop_String;
      begin
         Assert (Payload = "hello encrypted",
                 "CURVE encrypted message round-trips correctly");
      end;
   end;

   Put_Line ("");

   --  Test 7: Configure PLAIN authentication
   Put_Line ("-- PLAIN configuration --");
   declare
      Auth : CZMQ.Authentication.Authenticator :=
        CZMQ.Authentication.New_Authenticator;
      Password_File : constant String := "test_passwords_tmp.txt";
      F : Ada.Text_IO.File_Type;
   begin
      --  Create a simple password file (user=password format)
      Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Password_File);
      Ada.Text_IO.Put_Line (F, "admin=secret123");
      Ada.Text_IO.Close (F);

      Auth.Configure_Plain (Password_File);
      Assert (True, "Configure_Plain with password file succeeds");

      --  Clean up
      Ada.Directories.Delete_File (Password_File);
   end;

   Put_Line ("");

   --  Summary
   Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
             Natural'Image (Fail_Count) & " failed ===");

   if Fail_Count > 0 then
      raise Program_Error with "Test failures detected";
   end if;
end Test_Authentication;

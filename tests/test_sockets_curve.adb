--  Tests for CZMQ.Sockets CURVE and PLAIN options
--
--  Tests setting CURVE server mode, CURVE keys, PLAIN credentials,
--  and ZAP domain on sockets.

with Ada.Text_IO;
with CZMQ.Certificates;
with CZMQ.Sockets;

procedure Test_Sockets_Curve is

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
   Put_Line ("=== CZMQ.Sockets CURVE/PLAIN Tests ===");
   Put_Line ("");

   --  Test 1: Set CURVE server mode
   Put_Line ("-- CURVE server mode --");
   declare
      Server_Cert : CZMQ.Certificates.Certificate :=
        CZMQ.Certificates.New_Certificate;
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Socket (CZMQ.Sockets.Rep);
   begin
      Server_Cert.Apply (Sock);
      Sock.Set_Curve_Server;
      Assert (True, "Set_Curve_Server succeeds on REP socket");
   end;

   Put_Line ("");

   --  Test 2: Set CURVE server mode with explicit True/False
   Put_Line ("-- CURVE server enable/disable --");
   declare
      Cert : CZMQ.Certificates.Certificate := CZMQ.Certificates.New_Certificate;
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Socket (CZMQ.Sockets.Router);
   begin
      Cert.Apply (Sock);
      Sock.Set_Curve_Server (True);
      Assert (True, "Set_Curve_Server (True) succeeds");

      Sock.Set_Curve_Server (False);
      Assert (True, "Set_Curve_Server (False) succeeds");
   end;

   Put_Line ("");

   --  Test 3: Set CURVE server key on client socket
   Put_Line ("-- CURVE client configuration --");
   declare
      Server_Cert : CZMQ.Certificates.Certificate :=
        CZMQ.Certificates.New_Certificate;
      Client_Cert : CZMQ.Certificates.Certificate :=
        CZMQ.Certificates.New_Certificate;
      Client_Sock : CZMQ.Sockets.Socket :=
        CZMQ.Sockets.New_Socket (CZMQ.Sockets.Req);
   begin
      --  Apply client cert (sets public + secret key on socket)
      Client_Cert.Apply (Client_Sock);

      --  Set the server's public key so client knows who to trust
      Client_Sock.Set_Curve_Serverkey (Server_Cert.Public_Key);
      Assert (True, "Set_Curve_Serverkey with Z85 key succeeds");
   end;

   Put_Line ("");

   --  Test 4: Set ZAP domain
   Put_Line ("-- ZAP domain --");
   declare
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Socket (CZMQ.Sockets.Rep);
   begin
      Sock.Set_Zap_Domain ("global");
      Assert (True, "Set_Zap_Domain succeeds");
   end;

   Put_Line ("");

   --  Test 5: PLAIN server mode
   Put_Line ("-- PLAIN server mode --");
   declare
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Socket (CZMQ.Sockets.Rep);
   begin
      Sock.Set_Plain_Server;
      Assert (True, "Set_Plain_Server succeeds");
   end;

   Put_Line ("");

   --  Test 6: PLAIN client credentials
   Put_Line ("-- PLAIN client credentials --");
   declare
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Socket (CZMQ.Sockets.Req);
   begin
      Sock.Set_Plain_Username ("admin");
      Assert (True, "Set_Plain_Username succeeds");

      Sock.Set_Plain_Password ("secret123");
      Assert (True, "Set_Plain_Password succeeds");
   end;

   Put_Line ("");

   --  Test 7: Invalid socket raises
   Put_Line ("-- Error handling --");
   declare
      Sock : CZMQ.Sockets.Socket;  --  default, invalid
   begin
      Sock.Set_Curve_Server;
      Assert (False, "Set_Curve_Server on invalid socket should raise");
   exception
      when CZMQ.CZMQ_Error =>
         Assert (True, "Set_Curve_Server on invalid socket raises CZMQ_Error");
   end;

   Put_Line ("");

   --  Summary
   Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
             Natural'Image (Fail_Count) & " failed ===");

   if Fail_Count > 0 then
      raise Program_Error with "Test failures detected";
   end if;
end Test_Sockets_Curve;

--  Tests for CZMQ.Certificates
--
--  Tests certificate generation, key access, metadata, file I/O,
--  socket application, and equality comparison.

with Ada.Text_IO;
with Ada.Directories;
with CZMQ.Certificates;
with CZMQ.Sockets;

procedure Test_Certificates is

   use Ada.Text_IO;
   use type CZMQ.Certificates.Certificate;

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
   Put_Line ("=== CZMQ.Certificates Tests ===");
   Put_Line ("");

   --  Test 1: Generate a new certificate
   Put_Line ("-- New certificate generation --");
   declare
      Cert : CZMQ.Certificates.Certificate := CZMQ.Certificates.New_Certificate;
   begin
      Assert (Cert.Is_Valid, "New certificate is valid");

      --  Public key should be a 40-character Z85 string
      declare
         Pub : constant String := Cert.Public_Key;
      begin
         Assert (Pub'Length = 40, "Public key is 40 chars (Z85)");
         Assert (Pub /= (1 .. 40 => '0'), "Public key is not all zeros");
      end;

      --  Secret key should be a 40-character Z85 string
      declare
         Sec : constant String := Cert.Secret_Key;
      begin
         Assert (Sec'Length = 40, "Secret key is 40 chars (Z85)");
         Assert (Sec /= (1 .. 40 => '0'), "Secret key is not all zeros");
      end;
   end;

   Put_Line ("");

   --  Test 2: Two certificates should have different keys
   Put_Line ("-- Key uniqueness --");
   declare
      Cert_A : CZMQ.Certificates.Certificate := CZMQ.Certificates.New_Certificate;
      Cert_B : CZMQ.Certificates.Certificate := CZMQ.Certificates.New_Certificate;
   begin
      Assert (Cert_A.Public_Key /= Cert_B.Public_Key,
              "Two certificates have different public keys");
      Assert (not (Cert_A = Cert_B),
              "Two certificates are not equal");
   end;

   Put_Line ("");

   --  Test 3: Metadata
   Put_Line ("-- Metadata --");
   declare
      Cert : CZMQ.Certificates.Certificate := CZMQ.Certificates.New_Certificate;
   begin
      Cert.Set_Meta ("name", "test-server");
      Assert (Cert.Meta ("name") = "test-server",
              "Metadata 'name' round-trips correctly");

      --  Non-existent key returns empty string
      Assert (Cert.Meta ("nonexistent") = "",
              "Non-existent metadata returns empty string");
   end;

   Put_Line ("");

   --  Test 4: Save and load
   Put_Line ("-- Save and load --");
   declare
      Test_Dir  : constant String := "test_certs_tmp";
      Filename  : constant String := Test_Dir & "/test_cert";
      Pub_File  : constant String := Test_Dir & "/test_cert";
      Sec_File  : constant String := Test_Dir & "/test_cert_secret";
   begin
      --  Create temp directory
      if not Ada.Directories.Exists (Test_Dir) then
         Ada.Directories.Create_Directory (Test_Dir);
      end if;

      declare
         Original  : CZMQ.Certificates.Certificate :=
           CZMQ.Certificates.New_Certificate;
         Orig_Pub  : constant String := Original.Public_Key;
         Orig_Sec  : constant String := Original.Secret_Key;
      begin
         Original.Set_Meta ("name", "saved-cert");
         Original.Save (Filename);

         --  Both files should exist
         Assert (Ada.Directories.Exists (Pub_File),
                 "Public certificate file created");
         Assert (Ada.Directories.Exists (Sec_File),
                 "Secret certificate file created");

         --  Load and verify
         declare
            Loaded : CZMQ.Certificates.Certificate :=
              CZMQ.Certificates.Load (Filename);
         begin
            Assert (Loaded.Is_Valid, "Loaded certificate is valid");
            Assert (Loaded.Public_Key = Orig_Pub,
                    "Loaded public key matches original");
            Assert (Loaded.Secret_Key = Orig_Sec,
                    "Loaded secret key matches original");
            Assert (Loaded.Meta ("name") = "saved-cert",
                    "Loaded metadata matches original");
            Assert (Original = Loaded,
                    "Original and loaded certificates are equal");
         end;
      end;

      --  Clean up
      Ada.Directories.Delete_File (Pub_File);
      Ada.Directories.Delete_File (Sec_File);
      Ada.Directories.Delete_Directory (Test_Dir);
   end;

   Put_Line ("");

   --  Test 5: Save public only
   Put_Line ("-- Save public only --");
   declare
      Test_Dir : constant String := "test_certs_pub_tmp";
      Filename : constant String := Test_Dir & "/pub_cert";
   begin
      if not Ada.Directories.Exists (Test_Dir) then
         Ada.Directories.Create_Directory (Test_Dir);
      end if;

      declare
         Cert : CZMQ.Certificates.Certificate :=
           CZMQ.Certificates.New_Certificate;
         Orig_Pub : constant String := Cert.Public_Key;
      begin
         Cert.Save_Public (Filename);
         Assert (Ada.Directories.Exists (Filename),
                 "Public-only file created");

         declare
            Loaded : CZMQ.Certificates.Certificate :=
              CZMQ.Certificates.Load (Filename);
         begin
            Assert (Loaded.Public_Key = Orig_Pub,
                    "Public key matches after public-only save/load");
         end;
      end;

      --  Clean up
      Ada.Directories.Delete_File (Filename);
      Ada.Directories.Delete_Directory (Test_Dir);
   end;

   Put_Line ("");

   --  Test 6: Apply certificate to socket
   Put_Line ("-- Apply to socket --");
   declare
      Cert : CZMQ.Certificates.Certificate := CZMQ.Certificates.New_Certificate;
      Sock : CZMQ.Sockets.Socket := CZMQ.Sockets.New_Socket (CZMQ.Sockets.Push);
   begin
      --  Apply should not raise
      Cert.Apply (Sock);
      Assert (True, "Apply certificate to socket succeeds");
   end;

   Put_Line ("");

   --  Summary
   Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
             Natural'Image (Fail_Count) & " failed ===");

   if Fail_Count > 0 then
      raise Program_Error with "Test failures detected";
   end if;
end Test_Certificates;

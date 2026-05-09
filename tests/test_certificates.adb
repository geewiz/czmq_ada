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
   use CZMQ.Certificates;

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
      Assert (not Equal (Cert_A, Cert_B),
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
            Assert (Equal (Original, Loaded),
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

    Put_Line ("");

    --  Test 7: Generate/Close happy path
    Put_Line ("-- Generate/Close happy path --");
    declare
       Cert : CZMQ.Certificates.Certificate;
    begin
       Assert (not Cert.Is_Valid, "Default certificate is not valid");
       Cert.Generate;
       Assert (Cert.Is_Valid, "Generate makes certificate valid");
       Cert.Close;
       Assert (not Cert.Is_Valid, "Close makes certificate invalid");
    end;

    Put_Line ("");

    --  Test 8: Load procedure happy path
    Put_Line ("-- Load procedure happy path --");
    declare
       Test_Dir  : constant String := "test_certs_proc_tmp";
       Filename  : constant String := Test_Dir & "/proc_test_cert";
       Pub_File  : constant String := Test_Dir & "/proc_test_cert";
       Sec_File  : constant String := Test_Dir & "/proc_test_cert_secret";
    begin
       if not Ada.Directories.Exists (Test_Dir) then
          Ada.Directories.Create_Directory (Test_Dir);
       end if;

       declare
          Orig     : CZMQ.Certificates.Certificate :=
            CZMQ.Certificates.New_Certificate;
          Orig_Pub : constant String := Orig.Public_Key;
          Loaded   : CZMQ.Certificates.Certificate;
       begin
          Orig.Save (Filename);
          Loaded.Load (Filename);
          Assert (Loaded.Is_Valid, "Load procedure makes certificate valid");
          Assert (Loaded.Public_Key = Orig_Pub,
                  "Loaded public key matches original");
          Loaded.Close;
          Assert (not Loaded.Is_Valid, "Close makes loaded certificate invalid");
       end;

       --  Clean up
       Ada.Directories.Delete_File (Pub_File);
       Ada.Directories.Delete_File (Sec_File);
       Ada.Directories.Delete_Directory (Test_Dir);
    end;

    Put_Line ("");

    --  Test 9: Generate on already-valid certificate raises Program_Error
    Put_Line ("-- Generate on already-valid certificate --");
    declare
       Cert : CZMQ.Certificates.Certificate := CZMQ.Certificates.New_Certificate;
    begin
       Cert.Generate;
       Assert (False, "Generate on valid cert should raise Program_Error");
    exception
       when Program_Error =>
          Assert (True, "Generate on valid cert raises Program_Error");
    end;

    Put_Line ("");

    --  Test 10: Close on already-closed certificate is no-op
    Put_Line ("-- Close idempotent --");
    declare
       Cert : CZMQ.Certificates.Certificate;
    begin
       Cert.Close;  --  Should not raise
       Assert (True, "Close on already-closed certificate is no-op");
    end;

    Put_Line ("");

    --  Test 11: Operation on closed certificate raises CZMQ_Error
    Put_Line ("-- Operation on closed certificate --");
    declare
       Cert : CZMQ.Certificates.Certificate;
    begin
       Cert.Generate;
       Cert.Close;
       declare
          Key : constant String := Cert.Public_Key;
          pragma Unreferenced (Key);
       begin
          Assert (False, "Public_Key on closed cert should raise");
       end;
    exception
       when CZMQ.CZMQ_Error =>
          Assert (True, "Public_Key on closed cert raises CZMQ_Error");
    end;

    Put_Line ("");

    --  Test 12: Existing constructors still work after refactor
    Put_Line ("-- Constructors still work --");
    declare
       Cert_A : CZMQ.Certificates.Certificate := CZMQ.Certificates.New_Certificate;
       Cert_B : CZMQ.Certificates.Certificate;
    begin
       Assert (Cert_A.Is_Valid, "New_Certificate still works");
       Cert_B.Generate;
       Assert (Cert_B.Is_Valid, "Generate works");
    end;

    Put_Line ("");

    --  Summary
    Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
              Natural'Image (Fail_Count) & " failed ===");

    if Fail_Count > 0 then
       raise Program_Error with "Test failures detected";
    end if;
end Test_Certificates;

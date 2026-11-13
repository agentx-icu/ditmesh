import java.io.InputStream;
import java.nio.file.Path;
import java.security.CodeSigner;
import java.security.MessageDigest;
import java.security.cert.X509Certificate;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Set;
import java.util.jar.JarFile;
import javax.naming.ldap.LdapName;

/** Verify the random-access AAB format, regardless of ZIP manifest ordering.
 * JarFile verifies signatures while reading to EOF; it does not establish
 * certificate trust. The caller pins the leaf digest to the owner's identity.
 * https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/jar/JarFile.html
 */
public class VerifyAndroidBundle {
  public static void main(String[] args) throws Exception {
    boolean rejectDebug = args.length == 2 && args[1].equals("--reject-debug");
    if (args.length != 1 && !rejectDebug) {
      throw new IllegalArgumentException("Expected final AAB path and optional --reject-debug");
    }
    Set<String> fingerprints = new HashSet<>();
    int signedEntries = 0;
    try (JarFile jar = new JarFile(Path.of(args[0]).toFile(), true)) {
      if (jar.getManifest() == null || jar.getEntry("BundleConfig.pb") == null
          || jar.getEntry("base/manifest/AndroidManifest.xml") == null) {
        throw new SecurityException("Missing signed bundle structure");
      }
      var entries = jar.entries();
      while (entries.hasMoreElements()) {
        var entry = entries.nextElement();
        String name = entry.getName().toUpperCase(Locale.ROOT);
        // Only the JAR signing metadata is exempt. Ordinary META-INF payloads
        // (services, resources, etc.) still require verified signed entries.
        if (entry.isDirectory() || name.equals("META-INF/MANIFEST.MF")
            || name.matches("META-INF/[^/]+\\.(SF|RSA|DSA|EC)")) continue;
        try (InputStream stream = jar.getInputStream(entry)) {
          stream.transferTo(java.io.OutputStream.nullOutputStream());
        }
        CodeSigner[] signers = entry.getCodeSigners();
        if (signers == null || signers.length != 1) {
          throw new SecurityException("Unsigned or ambiguous AAB entry: " + entry.getName());
        }
        X509Certificate certificate = (X509Certificate) signers[0].getSignerCertPath().getCertificates().get(0);
        certificate.checkValidity();
        String fingerprint = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(certificate.getEncoded()));
        if (fingerprints.add(fingerprint) && rejectDebug) {
          for (var rdn : new LdapName(certificate.getSubjectX500Principal().getName()).getRdns()) {
            var commonName = rdn.toAttributes().get("CN");
            if (commonName != null && "Android Debug".equalsIgnoreCase(commonName.get().toString())) {
              throw new SecurityException("Android Debug certificate cannot sign a store AAB");
            }
          }
        }
        signedEntries++;
      }
    }
    if (signedEntries == 0 || fingerprints.size() != 1) {
      throw new SecurityException("Empty or inconsistent AAB upload identity");
    }
    System.out.println("SHA256: " + fingerprints.iterator().next());
  }
}

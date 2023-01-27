1. Prerequisites:
- Windows
- WSL
- dotnet on Windows and WSL
- Java keytool on WSL (install Java SDK)

2. Run `gen.sh` from WSL. This will create self-signed certificates and put the client cert in the application folder.
3. From the secrets folder, add `ca.crt` to the Windows trusted root certificate store.
4. On Windows, enter `127.0.0.1 kafka` in hosts file. It is necessary for the correct verification of the broker by hostname.
5. `sudo docker compose up` on WSL - we start kafka (sometimes, apparently, due to some kind of competition with the zookeeper, the container can crash due to a connection error with the zookeeper - start it again).
6. On WSL - `dotnet build TestProducer/TestProducer.csproj`. Go to the folder with the dll - so that the working directory is in the same place where the dll and certificates are - `cd TestProducer/bin/Debug/net6.0/`. Run the dll - `dotnet TestProducer.dll`.
7. You can open `http://localhost:8080` and be happy to see that something has entered our test topic.
8. Build and run now under Windows (VS / console), I will not repeat the commands.
9. For some reason, we immediately get `broker certificate could not be verified`. Even though `ca.crt` is listed and exists in the folder. Well, ok, comment the `SslCaLocation` parameter. Because in step 3, we added a certificate to the Windows store - by default application on Windows can take CA from there.
10. Commented out the line, run - we get `Disconnected while requesting ApiVersion`. On the broker in WSL at this moment `Empty client certificate chain`. How? For complacency, you can write full paths to files everywhere - the result is the same.
11. Do not forget to remove kafka from hosts and remove the certificate from the storage later.
12. Two bugs:
- Ignoring `SslCaLocation` from under Windows. Why climb into the repository if a specific cert is specified?
- The client certificate just doesn't work.
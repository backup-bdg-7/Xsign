import Foundation
import Security
import Vapor
import NIOSSL

/**
 * BackdoorTLS provides TLS certificate handling for the itms-services protocol.
 * iOS 13+ requires valid HTTPS for manifest delivery.
 * This implementation uses a pre-generated self-signed certificate for localhost.
 */
class BackdoorTLS {
    static let shared = BackdoorTLS()
    private init() {}
    
    struct Identity {
        let certPath: String
        let keyPath: String
    }
    
    func loadIdentity() -> Identity? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let certURL = docs.appendingPathComponent("localhost.crt")
        let keyURL = docs.appendingPathComponent("localhost.key")
        
        if !FileManager.default.fileExists(atPath: certURL.path) {
            generateIdentity(certURL: certURL, keyURL: keyURL)
        }
        
        return Identity(certPath: certURL.path, keyPath: keyURL.path)
    }
    
    private func generateIdentity(certURL: URL, keyURL: URL) {
        // Use embedded base64-encoded self-signed certificate and key
        // This certificate is for localhost and valid for itms-services protocol
        
        // Base64-encoded self-signed certificate for localhost
        let certBase64 = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURDVENDQWZHZ0F3SUJBZ0lVU1IwMkI0T3VwaUI0SmhWNG55YytFZElvYTI0d0RRWUpLb1pJaHZjTkFRRUwKQlFBd0ZERVNNQkFHQTFVRUF3d0piRzlqWVd4b2IzTjBNQjRYRFRJMk1EUXlNakl3TWpnek1sb1hEVEkzTURReQpNakl3TWpnek1sb3dGREVTTUJBR0ExVUVBd3dKYkc5allXeG9iM04wTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGCkFBT0NBUThBTUlJQkNnS0NBUUVBM1lzaFlRWDJOVytodmRER0lBdGNUK29kdldqRWpDYmpvMVJ1U3dZdUZsaGgKVStYcm5Ta2FHbE1ySHZCYyswOHd4Rm1XMmhDT29jN3BKMVpLaW5CZG05OXR1SGVrRVZESUlqM3FmVFpXZXFZQwpUZUd1MEdOTUVib0svazBwa3lPbWRQVjE5S1AwaHJpd0ZzWFYvTFYzb3l5R0dHRFlDVTBjaEFSOHdWc0srT2tKCllqZzJxQUx3ZUUwS2Ywa3ZaditQeHFDaVgyZUNFWUFFOHkydm4xSktYLzdWNW9zQmM5b05LbGM1ZXpERU85bGwKeWJLbXZkMGdOOVdqVkdJWlZudXJGbnlmK1RmekdNUkNJSkhVYUJoMHU4cGJndnN2eXUvU3I2bjlNUEpKL0l4Zgp0U2NkVm1UREhsa091ZHVKNlg4SEo5OHdZWEx0V1FDYUhKb3NyWWhlWVFJREFRQUJvMU13VVRBZEJnTlZIUTRFCkZnUVVGZ1NIbXdBK2lCb2t0b1AyOFp0VUY4VXpJT0F3SHdZRFZSMGpCQmd3Rm9BVUZnU0htd0EraUJva3RvUDIKOFp0VUY4VXpJT0F3RHdZRFZSMFRBUUgvQkFVd0F3RUIvekFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBTmJWeQp0OXFpUUlLSjg4WVF6MjAwVE1samlwa1BWVWl4a1dMZjhrQzliWlNIWmFaa25QMGo1MzdTMGZ4bGE1NTRwWmEyCmF5R1BtczFiUUJUYnpkS2FZWHpUWjRUcmppaVFtdmw3VFB6eWd1MkljZDhacW5KUjQ1Z2F0dE4vVlRMMzdHWHUKZ3NHUE5lY0gwaUFzN2ZxMHpKeXk4M2VnZzUxYmNZVC9nZGVsaU95WU04dW5kanpaQzY0M1o5OHhjc0pmemRjRAo1VXpnRFNrTU5yWVJKaVFtU3RjY2dHTFp3bjljTlhaUWdoVXU0K2QvZzZ1VjNNaXNPYmxIekRPZFphc0lTUzhHCk9PMzlpUEh6MHNrZkN6Nk0yeUEvTFRhRzVQUlFsZTZBWlA1SUtQRmg3VzdLR3QyNlZoZnBFMnZqMXQ0Q2hFQm0KaHFlbUpTNFcrOUFXYytkYldRPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="

        // Base64-encoded private key for localhost
        let keyBase64 = "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2UUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktnd2dnU0FnTUJBR0NDcUDZdzBDQVFFdwrL0xObUVsZk1BNnFHVnRBenVOaTd0NnVmOHYxUjVnRUREL2F3WmMwSDVtRnFEUXVPRDJERWVIbEY5R1NLCnh6YjV4TkhNTERmSG5yTk1LdU5pWUgyc0FyWkQ4Nk1Wb3k1RUNJakk4Q0FEb0Fwd2l3Y0RlNjErZmJJVGwKeU5UWmxnWHV6T3J5L2V5djQ2T1d5WndGQzVpR0FjeHdmN3daWHJCNFlRZk55QU50TVRjMHVFN0J5aDlwdgpVWEwrbXJPMjZScmNIWHQxOXVudmRNUjZXaFI4b0tWVVJaaW5xUHRoZ2Ryc0tXZz09Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0K"

        if let certData = Data(base64Encoded: certBase64) {
            try? certData.write(to: certURL)
        }
        
        if let keyData = Data(base64Encoded: keyBase64) {
            try? keyData.write(to: keyURL)
        }
    }
}

from Crypto.Cipher import AES
import binascii

def navicat_decrypt(hex_string):
    key = b"libcckeylibcckey"
    iv = b"libcciv libcciv "
    data = binascii.unhexlify(hex_string)
    cipher = AES.new(key, AES.MODE_CBC, iv)
    decrypted = cipher.decrypt(data)
    return decrypted.rstrip(b"\x00").decode(errors="ignore")

encrypted = "5F00740974608BB480586E572D0B21776088A525C8F99FC692138E1EDA47111A"
print(navicat_decrypt(encrypted))

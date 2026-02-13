---
title: Configuring Aerc to Work with Google Workspace via OAuth2
author: Nathaniel Chappelle
date: Thu, 12 Feb 2026 17:45:00 -0800
---

I recently set up aerc with Google Workspace, and like most people attempting
this in 2026 I ran straight into the challenges of modern authentication.

Google no longer allows basic username/password authentication for IMAP and SMTP
on most accounts. App passwords are increasingly restricted, especially in
managed Workspace environments. If you want your terminal mail client to keep
working, you need OAuth2.

Unfortunately, I couldn't find any guides that were complete and relevant,
except for [this one](https://lukaswerner.com/post/2024-07-08@aerc-outlook),
ironically written by a student of the same university I attend. This guide was
for Office365 emails, but it was a good starting point and pointed me towards
the `oauth2` script.

I wanted a setup that was:

- Secure (no stored passwords)
- Durable (not dependent on someone else’s client ID)
- Fully functional for both IMAP and SMTP
- Compatible with aerc’s native xoauth2 support

This post walks through the complete process of registering your own OAuth
client in Google Cloud, generating tokens using the OAuth2 script, and
configuring aerc to authenticate cleanly with STARTTLS.

## Prerequisites

This guide assumes some certain aspects of your environment:

- A Linux operating system (I use [Void](https://voidlinux.org/))
- A Python installation (< Python 3.7)
- [aerc](https://aerc-mail.org/), a pretty good email client
- The
  [`mutt_ouath2.py`](https://gitlab.com/muttmua/mutt/-/blob/master/contrib/mutt_oauth2.py)
  script
- GPG keys set up (technically optional but super recommended)

## Creating OAuth Credentials in Google Cloud

So our first step is to obtain vaid Google OAuth2 client ID's via the Google
Cloud Console. This is pretty simple:

1. Open the [clients](https://console.cloud.google.com/auth/clients) page of the
   Google Cloud Console.
2. Click the create a client button, and select 'Desktop App' as the application
   type from the dropdown.
3. Give your client a good name (like [jmail](https://jmail.world/))
4. This step is important. When you create the client ID a pop-up will show you
   your new client-id and client-secret. Make sure to save these in a good
   place.
5. If you created the OAuth2 credentials with your personal Google account, but
   your work account is the one you're trying to connect with aerc you will have
   to navigate to the [audience](https://console.cloud.google.com/auth/audience)
   tab and add your work account as a user.

Now you have your OAuth2 credentials, and we can move on to configuring aerc and
the OAuth2 script.

## Configuring the Script

I would place a copy of the `mutt_oauth2.py` script in your aerc config
directory, and then open it with your favorite text editor. Navigate to the
Google section of the `registrations` object. It should look something like
this:

```python
  'google': {
      'authorize_endpoint': 'https://accounts.google.com/o/oauth2/auth',
      'devicecode_endpoint': 'https://oauth2.googleapis.com/device/code',
      'token_endpoint': 'https://accounts.google.com/o/oauth2/token',
      'redirect_uri': 'urn:ietf:wg:oauth:2.0:oob',
      'imap_endpoint': 'imap.gmail.com',
      'pop_endpoint': 'pop.gmail.com',
      'smtp_endpoint': 'smtp.gmail.com',
      'sasl_method': 'OAUTHBEARER',
      'scope': 'https://mail.google.com/',
      'client_id': '',
      'client_secret': '',
  },
```

Now, I hope it is evident what you should do next, but in case it isn't just
copy the `client_id` and `client_secret` you saved earlier into their respective
positions within the object.

Additionally, make sure to input your GPG identity in the encryption and
decryption pipe arrays.

```python
ENCRYPTION_PIPE = ['gpg', '--encrypt', '--recipient', 'you@yourdomain.com']
DECRYPTION_PIPE = ['gpg', '--decrypt']
```

### Why Is This Important?

The token file created by mutt_oauth2.py contains your refresh token, which can
be used to generate new access tokens without your password or MFA. Because
OAuth tokens are bearer credentials, anyone who obtains that file can access
your mailbox. Encrypting it with GPG ensures that even if the file is copied,
synced, or backed up, it cannot be used without your private key.

But if you prefer simplicity, you can bypass encryption by replacing the GPG
pipes with something like:

```python
ENCRYPTION_PIPE = ['tee']
DECRYPTION_PIPE = ['cat']
```

This works because the script simply pipes JSON through those commands. However,
doing so stores the refresh token in plaintext, meaning security relies entirely
on filesystem permissions.

## First Time Authentication

Now you should be ready to create your local tokens. In your aerc configuration
directory you can run
`python3 mutt_oauth2.py --authorize you@yourdomain.com.tokens`. The script will
launch and take you through a interactive menu. It is self-explanatory except at
the auth-flow section. Here I chose `authcode` but you will probably be
successful with any of the choices. Assuming you chose `authcode`, the script
will then give you a url. Open it in a browser and be ready to copy the url
you'll be redirected to. Once you get that url, find the section which has
`code=` and copy the code. Paste that back into the script and the token file
will be created.

You can test it with `python3 mutt_oauth2.py you@yourdomain.com.tokens --test`.
If you don't see any errors you should be good to continue and start configuring
aerc.

## Configuring aerc

Aerc uses a very simple toml style configuration. The key aspects we're going to
to need to focus on is to use `xoauth2` for our `imaps` and `smtp`, as well as
using the `mutt_oauth2.py` script pointed towards the authentication tokens for
the `source-cred-cmd`. Here's what my config ended up looking like:

```toml
[yourdomain]
source            = imaps+xoauth2://you%40yourdomain.com@imap.gmail.com:993
source-cred-cmd   = "python3 /home/username/.config/aerc/oauth2.py /home/username/.config/aerc/you@yourdomain.com.tokens"
outgoing          = smtp+xoauth2://you%40yourdomain.com@smtp.gmail.com:587
outgoing-cred-cmd = "python3 /home/username/.config/aerc/oauth2.py /home/username/.config/aerc/you@yourdomain.com.tokens"
default           = INBOX
cache-headers     = true
from              = "Last Name, First Name" <you@yourdomain.com>
check-mail        = 5m
```

Gmail uses implicit TLS for IMAP on port 993 and STARTTLS for SMTP on port 587,
both of which are handled automatically by aerc.

That should be all you need. You can now start aerc and your Google Workspace
emails should start loading in.

## Conclusion

Setting up OAuth2 with aerc is more involved than pasting in a password, but it
results in a cleaner and more future-proof configuration.

Once configured, tokens refresh automatically, no passwords are stored in
plaintext, and aerc behaves like any other mail client, just faster , more
ergonomic, and entirely contained within the terminal.

Email authentication may be more complex than it used to be, but with the right
setup, it doesn’t have to get in the way of a minimal and keyboard-driven
workflow.

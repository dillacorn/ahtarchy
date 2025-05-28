notes from repo: https://github.com/dillacorn/arch-hypr-dots

# install brave from flathub
```sh
flatpak install flathub com.brave.Browser
```
---

### 🖥️ Hiding Brave from Wofi (and customizing launch options)

1. **Find the Flatpak `.desktop` file for Brave:**

```sh
find / -name 'com.brave.Browser.desktop' 2>/dev/null
```

2. **Edit the `.desktop` file to hide it from Wofi:**

Once located, open the file in a text editor and add this line **at the top**:

```ini
NoDisplay=true
```

> This prevents the default Brave launcher from appearing in Wofi or other app launchers.

3. **Use a custom `.desktop` file instead (optional):**

Drop this custom launcher into your local applications directory:

```sh
~/.local/share/applications/brave.desktop
```

Use the example from this GitHub repo:
[arch-hypr-dots/brave.desktop](https://github.com/dillacorn/arch-hypr-dots/blob/main/local/share/applications/brave.desktop)

4. **(Optional) Add a launch argument to handle passwords:**

In your custom `brave.desktop` file, modify the `Exec=` line to include:

```sh
--password-store=detect
```

For example:

```ini
Exec=flatpak run com.brave.Browser --password-store=detect %U
```

> This ensures Brave uses the correct password storage method based on your system.

---

# guide to make brave better
https://github.com/libalpm64/Better-Brave-Browser

# flags

navigate to: `brave://flags/`

### ✅ Required Flags to Disable (without the #)

brave-cosmetic-filtering-sync-load  
brave-rewards-verbose-logging  
brave-rewards-allow-unsupported-wallet-providers  
brave-rewards-allow-self-custody-providers  
brave-rewards-new-rewards-ui  
brave-rewards-animated-background  
brave-rewards-platform-creator-detection  
brave-ads-allowed-to-fallback-to-custom-push-notification-ads  
native-brave-wallet  
brave-wallet-zcash  
brave-wallet-bitcoin  
brave-wallet-enable-ankr-balances  
brave-wallet-enable-transaction-simulations  
brave-news-peek  
brave-news-feed-update  
ethereum_remote-client_new-installs  
brave-rewards-gemini  
brave-ai-chat  
brave-ai-chat-history  
brave-ai-chat-context-menu-rewrite-in-place  
brave-ai-chat-page-content-refine  
brave-ai-chat-open-leo-from-brave-search  
brave-ai-chat-web-content-association-default  
brave-ai-rewriter

### ⚙️ Optional Flags (without the #)

ozone-platform-hint → `Wayland`

fill-on-account-select → `Disabled`

enable-pending-mode-passwords-promo → `Disabled`

# extensions

Privacy centric extensions:
[`uBlock Origin`](https://chromewebstore.google.com/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm)
[`LocalCDN`](https://chromewebstore.google.com/detail/localcdn/njdfdhgcmkocbgbhcioffdbicglldapd)
[`ClearURLs`](https://chromewebstore.google.com/detail/clearurls/lckanjgmijmafbedllaakclkaicjfmnk)

---
Must have Extra extensions:
[`Chrome Show Tab Numbers`](https://chromewebstore.google.com/detail/chrome-show-tab-numbers/pflnpcinjbcfefgbejjfanemlgcfjbna)
[`SponsorBlock`](https://chromewebstore.google.com/detail/sponsorblock-for-youtube/mnjggcdmjocbbbhaepdhchncahnbgone)
[`Disable YouTube Number Keyboard Shortcuts`](https://chromewebstore.google.com/detail/disable-youtube-number-ke/lajiknjoinemadijnpdnjjdmpmpigmge)
[`Return YouTube Dislike`](https://chromewebstore.google.com/detail/return-youtube-dislike/gebbhagfogifgggkldgodflihgfeippi)
[`Bitwarden Password Manager`](https://chromewebstore.google.com/detail/bitwarden-password-manage/nngceckbapebfimnlniiiahkandclblb)
[`ScrollAnywhere`](https://chromewebstore.google.com/detail/scrollanywhere/jehmdpemhgfgjblpkilmeoafmkhbckhi)

Extra extensions I can live without:
[`Dark Reader`](https://chromewebstore.google.com/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh)
[`Key Jump keyboard navigation`](https://chromewebstore.google.com/detail/key-jump-keyboard-navigat/afdjhbmagopjlalgcjfclkgobaafamck)
[`Go Back With Backspace`](https://chromewebstore.google.com/detail/go-back-with-backspace/eekailopagacbcdloonjhbiecobagjci)
[`Simple Translate`](https://chromewebstore.google.com/detail/simple-translate/ibplnjkanclpjokhdolnendpplpjiace)
[`DeArrow - Better Titles and Thumbnails`](https://chromewebstore.google.com/detail/dearrow-better-titles-and/enamippconapkdmgfgjchkhakpfinmaj)
[`Search by Image`](https://chromewebstore.google.com/detail/search-by-image/cnojnbdhbhnkbcieeekonklommdnndci)
[`DownThemAll!`](https://chromewebstore.google.com/detail/downthemall/nljkibfhlpcnanjgbnlnbjecgicbjkge)
[`Redirector`](https://chromewebstore.google.com/detail/redirector/ocgpenflpmgnfapjedencafcfakcekcd)

# `picture in picture` video tip 
- `Right-click` video `twice` and click `Picture in picture`

# custom dns server

navigate to `Privacy and security` in settings

enable `Use secure DNS`

add custom configured dns server from personal provider ~ I pay for nextdns ($2 a month)
### example dns server address

DNS-over-HTTPS: `https://dns.nextdns.io\xxxxxxx`

see [yokoffing](https://github.com/yokoffing) ["NextDNS-Config" Guidelines](https://github.com/yokoffing/NextDNS-Config?tab=readme-ov-file)

# test browser security
https://browserleaks.com/webrtc

# personal settings

enable `Show home button` and add your preferred URL.. in my case "flame" and/or "hoarder" self hosted instance

disable `Show bookmarks bar`

# web apps

Place to manage your web apps: `brave://apps/`

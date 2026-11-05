class_name Legal
## The pages a new player agrees to on the account card (AccountScreen): the
## Terms, Community Guidelines, Privacy Policy, Disclaimer, and Child safety.
## Each is [title, text]; the text can use BBCode ([b]bold[/b]).
##
## These are first drafts, in plain words, to review before Gold Coast goes
## public (they aren't legal advice). When they change in a way players must
## agree to again, change Online.TERMS_VERSION and the server's TERMS_VERSION
## (server/modules/gold_coast.lua) together.

const UPDATED := "Draft of 30 October 2026"

const DOCUMENTS := {
	"terms": ["Terms of Use", """[b]Welcome to Gold Coast.[/b] By making an account, you agree to these terms.

[b]Who can play online.[/b] You must be 18 or older to make an account. One account per person, please.

[b]Your account.[/b] Keep your password to yourself. You're responsible for what happens on your account. Your username is seen by other players, so choose one that's kind and doesn't share personal details.

[b]Playing together.[/b] Gold Coast online is one shared town. Follow the Community Guidelines. We can suspend or close accounts that break them.

[b]The game.[/b] Gold Coast is free, and it's still being made: things will change, and sometimes break. We may reset progress during development. The game is given "as is", without promises that it will always be available or free of mistakes.

[b]Changes.[/b] If these terms change, we'll ask you to agree again before you play online.

[b]Questions.[/b] Contact us through the game's itch.io page: https://nobaddays.itch.io/gold-coast"""],
	"guidelines": ["Community Guidelines", """Gold Coast is a friendly town. Help keep it that way.

[b]Be kind.[/b] No bullying, harassment, threats, or hate (about race, ethnicity, religion, gender, sexuality, disability, or anything else).

[b]Keep it clean.[/b] No sexual content, and nothing violent or shocking.

[b]Keep it safe.[/b] Don't share your own or anyone else's personal details (phone numbers, addresses, passwords, money accounts). Don't pretend to be someone else.

[b]Play fair.[/b] No cheating, hacking, or using mistakes in the game to spoil it for others. If you find a mistake, tell us.

[b]No scams.[/b] Gold Coast's cedis are pretend money. Never trade real money or real things for anything in the game.

[b]Usernames[/b] follow the same rules.

Breaking these guidelines can lead to a warning, a suspension, or losing your account."""],
	"privacy": ["Privacy Policy", """[b]What we keep.[/b] When you make an account, Gold Coast's server keeps:
- your name and your username
- your email address
- your date of birth, and when you agreed to these pages
- your password, scrambled so nobody can read it (not even us)
- your game: your progress, money, and saved games

[b]Why.[/b] To give you an account, keep your game safe on the server, check you're 18 or older, and (later) let you reset a forgotten password and play with others.

[b]Who sees what.[/b] Other players see only your username (and, in the shared town, your character). Your name, email, and date of birth are private.

[b]What we don't do.[/b] We don't sell your information, show ads, or track you around the internet.

[b]Where it's kept.[/b] On Gold Coast's server. Your game is also saved in your own browser.

[b]How long.[/b] Until you delete your account, or ask us to.

[b]Your choices.[/b] You can ask to see your information, or to delete your account and everything in it, through the game's itch.io page: https://nobaddays.itch.io/gold-coast"""],
	"disclaimer": ["Disclaimer", """Gold Coast is a game, a story inspired by life in Ghana.

[b]It's made up.[/b] Its town, people, shops, and stories are imaginary. Any likeness to real people or places is by chance.

[b]Its money is pretend.[/b] Cedis, mobile money, rent, and prices in the game aren't real money and aren't linked to any real bank or mobile money service. Nothing in the game is financial advice.

[b]It's still being made.[/b] Things may change, break, or be reset while Gold Coast is being built."""],
	"child_safety": ["Child safety", """[b]Gold Coast online is for adults: 18 and older.[/b]

Making an account needs your date of birth, and the server checks it. We don't knowingly keep information about anyone under 18. If we learn that an account belongs to someone under 18, we close it and delete its information.

Everyone can play offline (single player, saved in the browser) without an account.

[b]If you're worried[/b] about a child's safety, or think a player is under 18, please tell us through the game's itch.io page: https://nobaddays.itch.io/gold-coast"""],
}


## The page's title, or "" if there's no such page.
static func title(key: String) -> String:
	return DOCUMENTS[key][0] if DOCUMENTS.has(key) else ""


## The page's text (BBCode), with the date it was last changed.
static func text(key: String) -> String:
	return "%s\n\n[i]%s[/i]" % [DOCUMENTS[key][1], UPDATED] if DOCUMENTS.has(key) else ""

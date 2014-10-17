# Helm
### Run commands across a filtered list of servers

Here's the idea, and it's very simple: you maintain a little database of the
servers you work with. You have some commands you run parameterized in
relationship to those servers. Those commands are all available as subcommands
of helm.

Helm does this:

```
helm uptime

Some Server (1.2.3.4)
Linux some-server 3.17.0 #3 SMP Wed Apr 24 18:32:26 GMT 2013 x86_64 Intel(R)
Xeon(R) CPU E5-2650 0 @ 2.00GHz GenuineIntel GNU/Linux
 17:41:27 up 296 days, 16:55,  0 users,  load average: 0.00, 0.01, 0.05

Another Server (3.4.5.6)
...
```

But you can also filter servers:

```
helm uptime --name "Some Server"

Some Server (1.2.3.4)
Linux some-server 3.17.0 #3 SMP Wed Apr 24 18:32:26 GMT 2013 x86_64 Intel(R)
Xeon(R) CPU E5-2650 0 @ 2.00GHz GenuineIntel GNU/Linux
 17:41:27 up 296 days, 16:55,  0 users,  load average: 0.00, 0.01, 0.05
```

That's pretty much it's job. There are also commands to list the servers it
knows about in a useful if unattractive table format, edit server records in
your favorite editor, and bulk add server records generated through other
tools.

Yep, it's pretty simple, but that's the idea: do one thing well.

## But isn't there already...

Capistrano? SSHKit? Yes. Those exist, and they're fine tools. There were a
couple of reasons I wanted something different. _(here, I rationalize my NIH
syndrome)_ Capistrano is build on top of SSHKit, so I'm only going to address
the latter.

First, SSHKit is built with the assumption of deployment: you configure all the
servers for a particular app, and put them into roles. While that heirarchy
makes sense for many use cases, I found that I often needed to do things with
servers across deploys - like check uptime, or versions of packages. A database
query makes more sense for that than a tree-node-selection.

Second, SSHKit is build with this (in my opinion) weird approach of sending all
it's commands individually over SSH, rather than batching them together into a
script and running it locally there. It works hard to provide that feature, and
it's neat, but for my purposes it's overkill.

Third, not all the commands I want to run against a set of servers are SSH
commands - I know Capistrano can help with that, but setting up those commands
is ultimately pretty arcane.

## Future Plans

Right now, Helm has a simple, single-table database structure and a whole 1
command (the uptime from above, which is pretty cool, though.) Both of those
things will likely expand to cover more use cases as I figure things out.

Also, so far, I'm the only one using Helm, and I've been puzzling out the
design as I went. There's probably docs needed for setting up and building
commands etc.

Helm definitely is ready to be extended to be more flexible - a config file to
manage a lot of the settings, and simple addition of new commands are the two
biggies. Expect those soon, especially if there's any interest in this thing.

# Introduction

Let's learn about how to make high scale websites. Each chapter will start out with a story of a system to build, and the book will go into depth about some of the trade-offs delved into. It's important to ask clarifying questions, so we don't build the wrong thing, and to make sure we meet the goals of the system, since technology exists to fulfill needs in the real world.

## A Gaming Server

We'll start out with a smaller scale system for this chapter. Imagine you want to play Minecraft with your friends, and have decided to host your own server. Normally, you would have one of your friends host the server, but that doesn't have enough availability for you. If the assigned friend who owns the server data goes on vacation, they would have to hand off the server data to another friend, and all your friends have to update their settings to login to that server. As well, if the first friend who runs the server goes on an unplanned vacation, the server won't be running, so the rest of you can't play.

One of your friends could use an old computer as the server, but that comes with its own issues -- they would need to somehow have a static ip, and if the power goes out, they would have to turn back on the server. Also, if the computer fails, or the hard drive fails, then the server's data could be lost forever. Also, that friend would have to always maintain a good enough internet connection for your friends to connect to (lag is the enemy of all gamers, after all).

You've decided to rent out a Virtual Private Server (VPS), and pay someone else to maintain the hardware, electricity, and internet connection. This costs $5 a month to get rid of all the headache of managing the actual computer that will act as our server.

You ssh into the server, download the server software, set it up, allow connections onto the required port, disallow connections to any other ports, and you have yourself a working system. Congratulations!

## All good things must come to an end

After playing on the server has gone smoothly for months, one day, you login to your beloved server and find that you have been "griefed". You and your friends were trying to build a replica of the Space Station in Minecraft, but it has been dynamited to smithereens. Who could've done this? Sadly, Nobody knows.

Before pointing fingers, you remember that anybody can log into your server, as you didn't require any authentication, so it doesn't have to be one of your friends. That's a relief.

Secondly, to make sure nothing like this happens again, you start to think about enabling audits on the server. You'd like to know who logs in, and having every action they make jotted down, so you know who's a nefarious actor to ban from the server if they do anything bad.

But that won't bring back the state of the server. You suggest creating backups -- every day, you save the state of the server, and write it to a file. This file is saved on the server, and an administrator can rollback to any previous state. Since our server is pretty small, and we have plenty of space for now, you store backups for a year.

Eventually the griefer comes back, trying to destroy your next creation, a life sized replica of the Eiffel Tower. Your auditing catches them, you ban the griefer, and roll back the state to before they could blow up your half completed tower.

Wonderful. Now you can sleep peacefully.

## The Server slows down

Your system works well -- so well, in fact, that your friends start referring their friends to join your server, and they refer their friends too! You now have so many players at any given time that the server you originally rented out is starting to lag during peak hours. That's not good. You rent out a bigger computer from your VPS provider, and everyone is happy for a bit. Until it happens again. You can't afford a bigger computer, so you decide to dig in and learn more.

You need some analytics. You decide to install Grafana and Prometheus, which provide metrics about your rented computer. You keep metrics for 14 days, so if one of your users notices bad performance, they can tell you the time it happened and you can figure out what server statistics correlates with bad performance.

You start by looking at Disk space, Disk I/O rate, CPU usage, and RAM usage. You note that the reports correspond to high rates of Disk I/O. With that information, you decide to upgrade your computer from a standard hard drive to a solid state disk (SSD), so disk writes are much faster.

## Conclusion

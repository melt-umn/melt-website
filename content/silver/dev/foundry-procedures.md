---
title: Foundry Procedures
weight: 300
---

This is a reference for how to do a few tasks on foundry, the shared server.

## Take a backup of Jenkins

There's a script in `/hdd/jenkins-backups/backup.sh` that automates the process of taking a snapshot of Jenkins, compressing it, and storing it as a file.
This should be run before making any nontrivial configuration change to Jenkins (and ideally we'd automate it, but that's NYI).

Don't store the backups on `/` (including in your home folder) -- they don't need to be fast, and we have far more free space on `/hdd`.
Ideally, store a copy of the backup off of foundry too.
We don't really have a designated place for this at the moment, but if you need somewhere, ask Nathan.

## Run commands in the Jenkins container

To run commands as the Jenkins user, `docker exec -it jenkins bash`.

To run commands as root, `docker exec -itu 0 jenkins bash`.

## Install software in the Jenkins container

The Jenkins container is running a sufficiently old version of Debian that lots of things we want aren't in apt (at least, not at versions we want).
Instead, we're building and installing stuff at `/export/scratch/thirdparty`.

Example:

```
# cd /export/scratch/thirdparty-src
# curl -L https://nodejs.org/dist/v18.13.0/node-v18.13.0.tar.xz | tar xJ
# cd node-v18.13.0
# PATH=/export/scratch/thirdparty/gcc-12.2.0/bin:$PATH
# PATH=/export/scratch/thirdparty/python-3.11.1/bin:$PATH
# ./configure --prefix=/export/scratch/thirdparty/node-v18.13.0
# make -j $(nproc) -l $(nproc)
# make -j $(nproc) -l $(nproc) install
```

Please leave the source directory around; it's on the HDD, on which we have lots of free space, and it's helpful to have it if we need to debug or tweak something later.

## Check for disk corruption

`/hdd` is using ZFS, which provides integrity checking.
Currently, we're not running a RAID, so file corruption isn't easily recoverable.
However, it's still good to check if you're suspicious that something's gone horribly wrong.

Run `sudo zpool scrub hdd` to start a "scrub," where the machine reads over the entire disk and checks the hashes of every disk block against the ones recorded in the metadata.
This should happen automatically on a weekly schedule.

This takes a long time, so it gets run as a background job.
`zpool status` will show the progress.

```
$ zpool status
  pool: hdd
 state: ONLINE
  scan: scrub in progress since Thu Feb  2 14:09:01 2023
	69.8G scanned at 11.6G/s, 22.5M issued at 3.74M/s, 69.8G total
	0B repaired, 0.03% done, no estimated completion time
config:

	NAME        STATE     READ WRITE CKSUM
	hdd         ONLINE       0     0     0
	 sdb       ONLINE       0     0     0

errors: No known data errors
```

When it's finished, `zpool status` should return something like this:

```
$ zpool status
  pool: hdd
 state: ONLINE
  scan: scrub repaired 0B in 00:07:47 with 0 errors on Thu Feb  2 14:16:48 2023
config:

	NAME        STATE     READ WRITE CKSUM
	hdd         ONLINE       0     0     0
	 sdb       ONLINE       0     0     0

errors: No known data errors
```

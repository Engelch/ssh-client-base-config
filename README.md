# ssh-base-config

This is ssh-base-config. This repository is intended to be used by many users. It does not contain any encrypted files.

## Concept

A typical SSH setup consists of at least 3 repositories. The 4th repository contains keys and other material for the user when working for a company. This approach also supports multiple companies.

1. `ssh-base-config`
2. `ssh-<<user>>-config`
3. `ssh-<<company>>-config`
4. `ssh-<<user>>-<<company>>-config`

It is best to download these repositories first. While the ssh-base configuration is being set up, downloads, i.e. cloning, may fail due to SSH keys not being found.

The user should download this repository into a private area such as `~/p/`. Then the user should create a symbolic link (s-link) to `~/.ssh`.

All SSH repositories have the same structure; all elements are optional.

1. `Keys.<<user>>[--<<company>>]].d`
2. `Config.<<user>>[--<<company>>]].d`
3. `Other.<<user>>[--<<company>>]].d`
4. Requirement definitions

### Requirements Definitions

Requirements are usually defined in a `ssh-<<company>>-config` repository. Such a repository is
to be shared by several people. So several people share host definitions from the `Config-...-.d` directories. However, each person has their own key material for the host definitions in this repository.

This can be solved by referencing key material by a common name such as
`Keys.company.d`.

The company repository can express this by a file `require__Config.<<company>>.d__Keys.<<company>>.d`. This states that the `Config.<<company>>.d` of the current repository requires a `Keys.<<company>>.d` directory to be existing from another repository. This should be: `Keys.<<user>>[--<<company>>]].d`. 

To fix the name, a further symbolic link is introduced to link
`Keys.<<company>>.d` to `Keys.<<user>>[--<<company>>]].d`.

### Example

Here is the default ssh-base-config directory shared by all:

```bash
# s-linked files (all) from ~/companyA/ssh-companyA-config/ (usually maintained by companyA)
lrwxr-xr-x Config.companyA.d -> /Users/engelch/companyA/ssh-companyA-config/Config.companyA.d/
lrwxr-xr-x Other.companyA.d -> /Users/engelch/companyA/ssh-companyA-config/Other.companyA.d/
lrwxr-xr-x require__Config.companyA.d__Keys.companyA.d -> /Users/engelch/companyA/ssh-companyA-config/require__Config.companyA.d__Keys.companyA.d

# s-linked files (all) from ~/p/ssh-companyA-engelch-config/ (My personal key material when working for companyA)
# Keys.companyA.d points to Keys.companyA-engelch.d
lrwxr-xr-x Keys.companyA-engelch.d -> /Users/engelch/p/ssh-companyA-engelch-config/Keys.companyA-engelch.d/
lrwxr-xr-x Keys.companyA.d -> /Users/engelch/p/ssh-companyA-engelch-config/Keys.companyA.d/
lrwxr-xr-x Other.companyA-engelch.d -> /Users/engelch/p/ssh-companyA-engelch-config/Other.companyA-engelch.d/

# s-linked files (all) from ~/p/ssh-engelch-config. (My private key material)
lrwxr-xr-x Config.engelch.d -> /Users/engelch/p/ssh-engelch-config/Config.engelch.d/
lrwxr-xr-x Keys.engelch.d -> /Users/engelch/p/ssh-engelch-config/Keys.engelch.d/
lrwxr-xr-x Other.engelch.d -> /Users/engelch/p/ssh-engelch-config/Other.engelch.d/

# files created by install-ssh
lrwxr-xr-x aws -> ./Other.companyA-engelch.d/aws/
lrwxr-xr-x gnupg -> ./Other.engelch.d/gnupg/
lrwxr-xr-x authorized_keys -> ./Other.companyA-engelch.d/authorized_keys
-rw-r--r-- completion.lst
-rw-r--r-- config
lrwxr-xr-x gitconfig -> ./Other.engelch.d/gitconfig
lrwxr-xr-x known_hosts -> ./Other.companyA-engelch.d/known_hosts

# The only files in ssh-base-config.
-rwxr-xr-x install-ssh.sh*
-rw-r--r-- README.md
```

## Installation Steps

1. Clone all repositories
2. Optionally decrypt repositories ([git gee](https://github.com/engelch/ConfigShell) is your friend)
3. Clean up existing parts as `~/.ssh`
4. S-link ssh-base-config as `~/.ssh`
5. Go to `~/.ssh`
6. For each other `ssh-...-config` repository:
   1. `ln -s <<repositoryPath>>/* .`
7. `./install-ssh.sh`

## install.ssh

The script checks for none, one, or multiple occurrences of directories `aws` and `gnupg` and the same for the file `gitconfig`.
If one exists, it is linked to `~/.ssh` and to the home directory like `~/.aws -> .ssh/aws`.

If multiple occurrences exist, `install-ssh.sh` asks which one to link to `~/.ssh`.

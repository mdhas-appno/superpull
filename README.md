# superpull
Simple script to git pull from all your repos in a directory at the same time

# installation
```bash
chmod +x superpull.sh
```

 ## adding it to your shell
 add this line to your shell

 ```bash
alias superpull='/path/to/your/script/superpull.sh'
```

### Going a bit deeper (Arguments)

Here are the arguments, virtually everything is optional. So you can run ./superpull.sh directly and have it work.

  --summary  Show summary only
  --verbose  Show detailed information
  --path     Specify a path to check (optional)
  --fast-forward  Enable fast-forward merges (optional)
  --help     Display this help message

However if all you want to see is a summary of everything it did then include --summary or if you want the verbose output which details every fetch/pull/merge etc then add --verbose.


> [!tip]
> if you want to make this faster `ssh-add <your key>`

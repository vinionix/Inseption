# Local secrets

Create these files locally before starting the project:

```text
db_password.txt
db_root_password.txt
wp_password.txt
wp_root_password.txt
```

Each file must contain only the secret value, without a variable name or quotes.

Example:

```sh
printf '%s' 'your-secret-value' > srcs/secrets/db_password.txt
chmod 600 srcs/secrets/*.txt
```

Never commit the `.txt` files from this directory.

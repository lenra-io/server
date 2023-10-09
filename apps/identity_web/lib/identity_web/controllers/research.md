- Login with Lenra
  - Get all accounts in session [get_session(:login_challenge)]
    * If no account
      - show Login/Register form.
    * else if one or more accounts
      - show account selection form. [put_session(:login_challange, :user_id, :email, :remember_me)]
  - Consent to the app [Previous account]
  - Logged to Lenra_app
- Logout
  - Idem as `Get all accounts in session`

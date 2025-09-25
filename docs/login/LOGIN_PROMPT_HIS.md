# PRE PROMPT
    - *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
    - First read `docs/login/LOGIN_SUMMARY.md` file for review your memory and brainstrom your self.
    - For better answer me please read your mememory inside file `docs/login/LOGIN_SUMMARY.md`
    - To give me better answers, please write a summary or review or document of each response to a file named `docs/login/LOGIN_SUMMARY.md`, so AI can remember and improve my prompts next time.
    - *important* I'm giving you the Document functionality, so try not to mess with the other features.
    - *important* after finish add command or type in terminal `say "For sell story"`

Topic: Flow password reset
Detail: I attach image is show text like '{last4}' and '{secound}', it should be last 4 digit and second digit.Fix it.

Topic: Flow password reset
Detail: Change alert text in requestOtp function when request fail to "เกิดข้อผิดพลาด กรุณาติดต่อ admin sellstory"

```
 else {
        errorMessage = 'request_failed'.tr;
      }
```

Topic: Open link in app
Detail: When pressed link where "สอบถามเพิ่มเติม Link" in login page, should open link in app not open external browser.

##

Topic: When login not success change alert.
Detail: When login not success or any error fix show text only "Invalid email or password"

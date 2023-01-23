Adding a new Stylus style:

* Create the style file using the user.css file format
  * Name the file like `trello.user.css`
* Push to the repo
* In a new browser window:
  * go to the Github repo
  * open the file in RAW mode in the browser (button on the file display in github)
  * Stylus should open the file as soon as you view it
* Click the `Install style` button from Stylus
* Click the `Edit` button to change the title (it defaults to a time stamp)
* Return to the `Manage` view in Stylus to confirm that the style is loaded and up to date

You can edit locally to test things, but be sure to edit in the source file and push to the repo to use the new edits everywhere and always (else changes are lost after the browser is closed).

Be sure to update the `@version` field in the user css header on the file before pushing (else it will note be reloaded by Stylus).

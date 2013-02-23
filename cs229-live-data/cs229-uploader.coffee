UploadedFiles = new Meteor.Collection("uploaded_files")

if Meteor.isClient
  Template.uploadedFiles.files = ->
    UploadedFiles.find({user_email: Session.get("userEmail")}, {created_at: -1})

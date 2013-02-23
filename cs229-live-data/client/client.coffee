$(document).ready ->
  Template.uploadedFiles.events =
    'change': (event) ->
      UploadedFiles.update { _id: this._id }, { $set: { grade: $(event.srcElement).attr('value') } }

  Template.uploadedFiles.grades = ->
    array = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F']
    gradeHash = []
    for grade, i in array
      if this.grade == grade
        gradeHash[i] = {selected: true, grade: grade}
      else
        gradeHash[i] = {selected: false, grade: grade}

    return gradeHash

  Template.uploadedFiles.isSelected = ->
    return true if this.selected
    return false

  loadFiles = (callback) ->
    filepicker.pick([], callback)

  $(".login input[name=sign-in]").live "click", (event) ->
    event.preventDefault()
    value = $("input[name=email]").attr("value")
    if value != ""
      $(".login").hide()
      $(".files").show()
      Session.set("userEmail", value)
    else
      alert("Please enter an email!")

  $("button[name=upload-file]").live "click", ->
      loadFiles (fpfile) ->
        fpfile.created_at = new Date()
        fpfile.user_email = Session.get("userEmail")
        UploadedFiles.insert(fpfile)
        $("#thanks").html(Template.thanks())

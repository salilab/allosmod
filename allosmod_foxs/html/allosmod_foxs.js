function add_structure() {
  var numrows = $("#structures tr").length;
  var row = '<tr>' +
            '<td>PDB code <input type="text" name="pdbcode' + numrows +
                           '"  size="5" /></td>' +
            '<td>or upload file <input type="file" ' +
                     'name="uploaded_file' + numrows + '"  /></td>' +
            '</tr>'
  $(row).appendTo("#structures");
}

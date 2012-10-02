function add_structure() {
  var row = '<tr>' +
            '<td>PDB code <input type="text" name="pdbcode"  size="5" /></td>' +
            '<td>or upload file <input type="file" ' +
                     'name="uploaded_file"  /></td>' +
            '</tr>'
  $(row).appendTo("#structures");
}

function add_structure() {
  var row = '<tr>' +
            '<td>PDB code <input type="text" name="pdbcode"  size="4" /></td>' +
            '<td>or upload PDB file <input type="file" ' +
                     'name="uploaded_file"  /></td>' +
            '</tr>'
  $(row).appendTo("#structures");
}

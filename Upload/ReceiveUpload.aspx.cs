using System;
using System.Data;
using System.Configuration;
using System.Collections;
using System.Collections.Specialized;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
	
public partial class ReceiveUpload : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        HttpFileCollection uploadFiles = Request.Files;
	
        // Build HTML listing the files received.
        string summary = "<p>Files Uploaded:</p><ol>";
	
        // Loop over the uploaded files and save to disk.
        int i;
        for (i = 0; i < uploadFiles.Count; i++)
        {
            HttpPostedFile postedFile = uploadFiles[i];
	
            // Access the uploaded file's content in-memory:
            System.IO.Stream inStream = postedFile.InputStream;
            byte[] fileData = new byte[postedFile.ContentLength];
            inStream.Read(fileData, 0, postedFile.ContentLength);
	
            // Save the posted file in our "data" virtual directory.
            postedFile.SaveAs(Server.MapPath("data") + "\\" + postedFile.FileName);
	
            // Also, get the file size and filename (as specified in
            // the HTML form) for each file:
            summary += "<li>" + postedFile.FileName + ": "
                + postedFile.ContentLength.ToString() + " bytes</li>";
        }
        summary += "</ol>";
	
        // If there are any form variables, get them here:
        summary += "<p>Form Variables:</p><ol>";
	
        //Load Form variables into NameValueCollection variable.
        NameValueCollection coll = Request.Form;
	
        // Get names of all forms into a string array.
        String[] arr1 = coll.AllKeys;
        for (i = 0; i < arr1.Length; i++)
        {
            summary += "<li>" + arr1[i] + "</li>";
        }
        summary += "</ol>";
	
        divContent.InnerHtml = summary;
    }
}
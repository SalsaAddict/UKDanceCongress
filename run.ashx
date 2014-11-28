<%@ WebHandler Language="C#" Class="run" %>

using Newtonsoft.Json;
using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.IO;
using System.Web;
using System.Xml;

public class run : IHttpHandler
{

    public void ProcessRequest(HttpContext context)
    {
        if (context.Request.QueryString.Count >= 1)
        {
            try
            {
                using (SqlConnection Connection = new SqlConnection(ConfigurationManager.ConnectionStrings["UKDC"].ConnectionString))
                {
                    Connection.Open();
                    using (SqlCommand Command = new SqlCommand())
                    {
                        Command.Connection = Connection;
                        Command.CommandType = CommandType.StoredProcedure;
                        Command.CommandText = string.Format("WebApi{0}", context.Request.QueryString[0]);
                        for (int i = 1; i < context.Request.QueryString.Count; i++)
                        {
                            Command.Parameters.AddWithValue(
                                context.Server.UrlDecode(context.Request.QueryString.Keys[i]),
                                context.Server.UrlDecode(context.Request.QueryString[i]));
                        }
                        if (context.Request.HttpMethod == "POST")
                        {
                            string Body = string.Empty;
                            using (StreamReader Reader = new StreamReader(context.Request.InputStream, context.Request.ContentEncoding))
                            {
                                Body = Reader.ReadToEnd();
                            }
                            if (!string.IsNullOrWhiteSpace(Body))
                            {
                                XmlDocument RequestXml = JsonConvert.DeserializeXmlNode(Body, "Root", true);
                                Command.Parameters.AddWithValue("XML", RequestXml.OuterXml);
                            }
                        }
                        XmlDocument ResponseXml = new XmlDocument();
                        ResponseXml.Load(Command.ExecuteXmlReader());
                        context.Response.ContentType = "text/json";
                        context.Response.Write(JsonConvert.SerializeXmlNode(ResponseXml, Newtonsoft.Json.Formatting.Indented, true));
                    }
                    Connection.Close();
                }
            }
            catch (Exception ex)
            {
                context.Response.Clear();
                context.Response.StatusCode = 500;
                context.Response.StatusDescription = ex.Message;
            }
        }
    }

    public bool IsReusable { get { return false; } }

}
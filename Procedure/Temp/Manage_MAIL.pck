CREATE_PACKAGE_HEADER(Manage_mail)
IS
/*****************************************************************
*  Package Info
*   Author        : $Author: JOTHOR $
*   Original Date   : $Date: 2004/11/11 10:28:31 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header: F:/Private/Repository/dbr/Procedure/Manage_mail.pck,v 1.5 2004/11/11 10:28:31 JOTHOR Exp $
*   Revision History  : $Revision: 1.5 $
*   Workfile      : $Workfile: $
*****************************************************************
* Description
*
* Mail servers:
* 1) mailhost.statoil.no      unix cluster for handling mail	
* 2) stfo-lnsmtp.statoil.no   primarily for inbound use, but handles both directions. Closing down year ca 2006
* 3) stfo-lnsmtp2.statoil.no  primarily for outbound use, but handles both directions.Closing down year ca 2006
* The mail servers do not perform virus scan on outbound messages.
*
* More details at : http://www.oracle.com/technology/sample_code/tech/pl_sql/htdocs/Utl_Smtp_Sample.html
*
* NOTE:
* CC and BCC do not work properly and have been deactivated.
*
* Usage:
* --------------------------------------------------------
* declare
* begin
*   Manage_mail.begin_mail(sender => 'foo@foobar.com'
* 		,recipients => 'another_foo@foobar.com'
* 		,subject => 'The attached report'
* 		,mime_type => Manage_mail.MULTIPART_MIME_TYPE -- example
* 		);
*   Manage_mail.attach_base64_text(data => lMyClobData
* 		,inline => false
* 		,filename => getNPDFileName
* 		,last => false
* 		);
*   Manage_mail.attach_base64_text(data => 'With regards' || 'Mee Namei'
* 		,inline => true
* 		,mime_type => 'text/plain'
* 		,last => true
* 		);
*   Manage_mail.end_mail;
* exception -- Important section, must not be omitted!
*   when others then
*     -- your exception handling here
* end;
* --------------------------------------------------------
* 
*****************************************************************/


/*****************************************************
* Variable
*****************************************************/
 PACKAGE_VARIABLE($Revision: 1.5 $);

  ----------------------- Customizable Section -----------------------


  -- Customize the signature that will appear in the email's MIME header.
  -- Useful for versioning.
  MAILER_ID   CONSTANT VARCHAR2(256) := 'Mailer by Oracle UTL_SMTP';

  --------------------- End Customizable Section ---------------------
  MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256):= 'MULTIPART_MIME_TYPE';
  MIME_TYPE_TEXTPLAIN CONSTANT VARCHAR2(256):= 'text/plain';
  MIME_TYPE_HTML CONSTANT VARCHAR2(256):= 'text/html';
  MIME_TYPE_APPLICATIONOCTET CONSTANT VARCHAR2(256):= 'application/octet';

/*****************************************************
* Method
*****************************************************/
  STD_PACKAGE_METHOD;

-- Sets the desired debug level.
  PROCEDURE(setDebugLevel)(pLevel number);

  -- Outputs a newline in the mail
  PROCEDURE(newLine)(last boolean default false);

/*****************************************************
* Should an exception occur in your programme, it is 
* important that this procedure (errorHandling) is called
* in the appropriate exception block.
* It will attempt to perform the necessary closure of 
* all open channel
*****************************************************/
  PROCEDURE(errorHandling);

  -- Appends attachment details at the end of the email.
  -- This must be set prior to each begin_mail
  PROCEDURE(setAttachmentInfo)(lAttachInfo in boolean);

  -- A simple email API for sending email in plain text in a single call.
  -- The format of an email address is one of these:
  --   someone@some-domain
  --   "Someone at some domain" <someone@some-domain>
  --   Someone at some domain <someone@some-domain>
  -- The recipients is a list of email addresses  separated by
  -- either a "," or a ";"
  PROCEDURE mail(sender     IN VARCHAR2,
		 recipients IN VARCHAR2,
   	         lCC	    in varchar2 default null,
		 lBCC	    in varchar2 default null,
		 subject    IN VARCHAR2,
		 message    IN VARCHAR2);

  -- Extended email API to send email in HTML or plain text with no size limit.
  -- First, begin the email by begin_mail(). Then, call write_text() repeatedly
  -- to send email in ASCII piece-by-piece. Or, call write_mb_text() to send
  -- email in non-ASCII or multi-byte character set. End the email with
  -- end_mail().
  PROCEDURE(begin_mail)(sender   IN VARCHAR2,
		      recipients IN VARCHAR2,
		      lCC        in varchar2 default null,
		      lBCC       in varchar2 default null,
		      subject    IN VARCHAR2,
		      mime_type  IN VARCHAR2    DEFAULT MIME_TYPE_TEXTPLAIN,
		      priority   IN PLS_INTEGER DEFAULT NULL);

  -- Write email body in ASCII
  PROCEDURE write_text(message IN VARCHAR2);

  -- Write email body in non-ASCII (including multi-byte). The email body
  -- will be sent in the database character set.
  PROCEDURE write_mb_text(message IN            VARCHAR2);

  -- Write email body in binary
  PROCEDURE write_raw(message IN RAW);

  -- APIs to send email with attachments. Attachments are sent by sending
  -- emails in "multipart/mixed" MIME format. Specify that MIME format when
  -- beginning an email with begin_mail().

  -- Send a single text attachment.
  PROCEDURE attach_text(data         IN VARCHAR2,
			mime_type    IN VARCHAR2 DEFAULT MIME_TYPE_TEXTPLAIN,
			inline       IN BOOLEAN  DEFAULT TRUE,
			filename     IN VARCHAR2 DEFAULT NULL,
		        last         IN BOOLEAN  DEFAULT FALSE);

  -- Send a text attachment. The attachment will be encoded in Base-64
  -- encoding format.
  PROCEDURE(attach_base64_text)(data         IN VARCHAR2,
			  mime_type    IN VARCHAR2 DEFAULT MIME_TYPE_APPLICATIONOCTET,
			  inline       IN BOOLEAN  DEFAULT TRUE,
			  filename     IN VARCHAR2 DEFAULT NULL,
			  last         IN BOOLEAN  DEFAULT FALSE);

  -- Send a clob attachment. The attachment will be encoded in Base-64
  -- encoding format.
  PROCEDURE(attach_base64_text)(data   IN CLOB,
			  mime_type    IN VARCHAR2 DEFAULT MIME_TYPE_APPLICATIONOCTET,
			  inline       IN BOOLEAN  DEFAULT TRUE,
			  filename     IN VARCHAR2 DEFAULT NULL,
			  last         IN BOOLEAN  DEFAULT FALSE);

  -- Send a binary attachment. The attachment will be encoded in Base-64
  -- encoding format.
  PROCEDURE attach_base64(data         IN RAW,
			  mime_type    IN VARCHAR2 DEFAULT MIME_TYPE_APPLICATIONOCTET,
			  inline       IN BOOLEAN  DEFAULT TRUE,
			  filename     IN VARCHAR2 DEFAULT NULL,
			  last         IN BOOLEAN  DEFAULT FALSE);

/* Not to be exposed
  -- Send an attachment with no size limit. First, begin the attachment
  -- with begin_attachment(). Then, call write_text repeatedly to send
  -- the attachment piece-by-piece. If the attachment is text-based but
  -- in non-ASCII or multi-byte character set, use write_mb_text() instead.
  -- To send binary attachment, the binary content should first be
  -- encoded in Base-64 encoding format using the demo package for 8i,
  -- or the native one in 9i. End the attachment with end_attachment.
  PROCEDURE begin_attachment(mime_type    IN VARCHAR2 DEFAULT MIME_TYPE_TEXTPLAIN,
			     inline       IN BOOLEAN  DEFAULT TRUE,
			     filename     IN VARCHAR2 DEFAULT NULL,
			     transfer_enc IN VARCHAR2 DEFAULT NULL);

  -- End the attachment.
  PROCEDURE end_attachment(last IN BOOLEAN DEFAULT FALSE);
*/

  -- End the email.
  PROCEDURE end_mail;

/* Not to be exposed
  -- Extended email API to send multiple emails in a session for better
  -- performance. First, begin an email session with begin_session.
  -- Then, begin each email with a session by calling begin_mail_in_session
  -- instead of begin_mail. End the email with end_mail_in_session instead
  -- of end_mail. End the email session by end_session.
  PROCEDURE begin_session;

  -- Begin an email in a session.
  PROCEDURE begin_mail_in_session(sender     IN VARCHAR2,
				  recipients IN VARCHAR2,
				  lCC	     in varchar2 default null,
				  lBCC	     in varchar2 default null,
				  subject    IN VARCHAR2,
				  mime_type  IN VARCHAR2  DEFAULT MIME_TYPE_TEXTPLAIN,
				  priority   IN PLS_INTEGER DEFAULT NULL);

  -- End an email in a session.
  PROCEDURE end_mail_in_session;

  -- End an email session.
  PROCEDURE end_session;
*/
END_CREATE_PACKAGE_HEADER;


import React, { useState, useEffect } from "react";
import { Amplify } from "@aws-amplify/core";
import { Auth } from "@aws-amplify/auth";
import { withAuthenticator } from "@aws-amplify/ui-react";
import "@aws-amplify/ui-react/styles.css";
import "./App.css";

function App({ signOut, user }) {
  const [skills, setSkills] = useState("");
  const [jobDescription, setJobDescription] = useState("");
  const [resumeUrl, setResumeUrl] = useState("");
  const [message, setMessage] = useState("");

  const SAVE_PROFILE_API = "<save_profile_endpoint>";
  const GENERATE_RESUME_API = "<generate_resume_endpoint>";

  useEffect(() => {
    Amplify.configure({
      Auth: {
        region: "us-east-1",
        userPoolId: "<cognito_user_pool_id>",
        userPoolWebClientId: "<cognito_app_client_id>",
        oauth: {
          domain: "<cognito_domain without https://>",
          scope: ["email", "openid", "profile"],
          redirectSignIn: "<frontend_website_url>",
          redirectSignOut: "<frontend_website_url>",
          responseType: "token",
        },
      },
    });
  }, []);

  const handleSaveProfile = async (e) => {
    e.preventDefault();
    if (!user) return setMessage("Please sign in first");

    const token = (await Auth.currentSession()).getIdToken().getJwtToken();
    const payload = {
      userId: user.attributes.sub,
      skills: skills.split(",").map((skill) => skill.trim()),
      jobDescription,
    };

    try {
      const response = await fetch(SAVE_PROFILE_API, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": token },
        body: JSON.stringify(payload),
      });
      const data = await response.json();
      if (response.ok) {
        setMessage("Profile saved successfully!");
        setSkills("");
        setJobDescription("");
      } else {
        setMessage(`Error: ${data.message}`);
      }
    } catch (error) {
      setMessage(`Error: ${error.message}`);
    }
  };

  const handleGenerateResume = async () => {
    if (!user) return setMessage("Please sign in first");

    const token = (await Auth.currentSession()).getIdToken().getJwtToken();
    const payload = { userId: user.attributes.sub };

    try {
      const response = await fetch(GENERATE_RESUME_API, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": token },
        body: JSON.stringify(payload),
      });
      const data = await response.json();
      if (response.ok) {
        setResumeUrl(data.resumeUrl);
        setMessage("Resume generated! Download link below.");
      } else {
        setMessage(`Error: ${data.message}`);
      }
    } catch (error) {
      setMessage(`Error: ${error.message}`);
    }
  };

  return (
    <div className="App">
      <h1>SmartResume</h1>
      {user ? (
        <>
          <p>Welcome, {user.attributes.email}!</p>
          <button onClick={signOut}>Sign Out</button>
          <form onSubmit={handleSaveProfile}>
            <div>
              <label>Skills (comma-separated):</label>
              <input
                type="text"
                value={skills}
                onChange={(e) => setSkills(e.target.value)}
                placeholder="e.g., Python, AWS, React"
                required
              />
            </div>
            <div>
              <label>Job Description:</label>
              <textarea
                value={jobDescription}
                onChange={(e) => setJobDescription(e.target.value)}
                placeholder="Paste the job description here"
                required
              />
            </div>
            <button type="submit">Save Profile</button>
          </form>
          <button onClick={handleGenerateResume} disabled={!message.includes("saved")}>
            Generate Resume
          </button>
        </>
      ) : (
        <p>Please sign in to use SmartResume</p>
      )}
      {message && <p>{message}</p>}
      {resumeUrl && (
        <div>
          <a href={resumeUrl} target="_blank" rel="noopener noreferrer">
            Download Your Resume
          </a>
        </div>
      )}
    </div>
  );
}

export default withAuthenticator(App);

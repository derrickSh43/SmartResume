import React, { useState, useEffect } from "react";
import { Auth } from "aws-amplify";
import "./App.css";

function App() {
  const [user, setUser] = useState(null);
  const [skills, setSkills] = useState("");
  const [jobDescription, setJobDescription] = useState("");
  const [resumeUrl, setResumeUrl] = useState("");
  const [message, setMessage] = useState("");

  // Replace with Terraform outputs
  const SAVE_PROFILE_API = "https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/save-profile";
  const GENERATE_RESUME_API = "https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/generate-resume";

  // Configure Amplify (run once)
  useEffect(() => {
    Auth.configure({
      region: "us-east-1",
      userPoolId: "YOUR_USER_POOL_ID", // From cognito_user_pool_id output
      userPoolWebClientId: "YOUR_APP_CLIENT_ID", // From cognito_app_client_id output
      oauth: {
        domain: "resumerx-auth-abcd1234.auth.us-east-1.amazoncognito.com", // From cognito_domain output
        scope: ["email", "openid", "profile"],
        redirectSignIn: "http://your-s3-website-endpoint/",
        redirectSignOut: "http://your-s3-website-endpoint/",
        responseType: "token",
      },
    });

    // Check if user is already signed in
    Auth.currentAuthenticatedUser()
      .then((user) => setUser(user))
      .catch(() => setUser(null));
  }, []);

  const handleSignIn = () => {
    Auth.federatedSignIn();
  };

  const handleSignOut = () => {
    Auth.signOut().then(() => setUser(null));
  };

  const handleSaveProfile = async (e) => {
    e.preventDefault();
    if (!user) return setMessage("Please sign in first");

    const token = (await Auth.currentSession()).getIdToken().getJwtToken();
    const payload = {
      userId: user.attributes.sub, // Cognito user ID
      skills: skills.split(",").map((skill) => skill.trim()),
      jobDescription,
    };

    try {
      const response = await fetch(SAVE_PROFILE_API, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": token,
        },
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
        headers: {
          "Content-Type": "application/json",
          "Authorization": token,
        },
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
      <h1>ResumeRx</h1>
      {user ? (
        <div>
          <p>Welcome, {user.attributes.email}!</p>
          <button onClick={handleSignOut}>Sign Out</button>
        </div>
      ) : (
        <button onClick={handleSignIn}>Sign In</button>
      )}

      {user && (
        <>
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

export default App;
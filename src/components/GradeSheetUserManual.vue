<script setup>
defineProps({
  isOpen: {
    type: Boolean,
    required: true
  }
})

defineEmits(['close'])
</script>

<template>
  <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm transition-opacity">
    <div class="bg-white rounded-xl shadow-2xl max-w-4xl w-full max-h-[90vh] flex flex-col overflow-hidden">
      
      <!-- Header -->
      <div class="px-6 py-4 border-b border-slate-200 flex justify-between items-center bg-slate-50">
        <h2 class="text-xl font-bold text-slate-800">Advisory & Grading System — User Manual</h2>
        <button @click="$emit('close')" class="text-slate-500 hover:text-slate-800 p-2 rounded-full hover:bg-slate-200 transition-colors">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- Scrollable Content -->
      <div class="px-6 py-6 overflow-y-auto flex-1 text-slate-700 space-y-8">
        
        <p class="text-sm">Welcome to the Advisory & Grading System. This manual explains how to use the system based on your assigned teacher role.</p>

        <!-- Section 1 -->
        <section>
          <h3 class="text-lg font-bold text-slate-800 mb-3 border-b pb-2">1. Teacher Roles & Capabilities</h3>
          <div class="overflow-x-auto rounded-lg border border-slate-200">
            <table class="w-full text-left text-sm">
              <thead class="bg-slate-100 font-semibold text-slate-700">
                <tr>
                  <th class="p-3 border-b">Feature / Action</th>
                  <th class="p-3 border-b text-center">Subject Teacher (Non-Adviser)</th>
                  <th class="p-3 border-b text-center">Class Adviser</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200">
                <tr class="hover:bg-slate-50">
                  <td class="p-3 font-medium">Encode & save subject grades</td>
                  <td class="p-3 text-center">✅</td>
                  <td class="p-3 text-center">✅</td>
                </tr>
                <tr class="hover:bg-slate-50">
                  <td class="p-3 font-medium">Manage advisory class roster</td>
                  <td class="p-3 text-center">❌</td>
                  <td class="p-3 text-center">✅</td>
                </tr>
                <tr class="hover:bg-slate-50">
                  <td class="p-3 font-medium">View term grades summary</td>
                  <td class="p-3 text-center">❌</td>
                  <td class="p-3 text-center">✅</td>
                </tr>
                <tr class="hover:bg-slate-50">
                  <td class="p-3 font-medium">Finalize term grades</td>
                  <td class="p-3 text-center">❌</td>
                  <td class="p-3 text-center">✅</td>
                </tr>
                <tr class="hover:bg-slate-50">
                  <td class="p-3 font-medium">Sync records to Google Sheets</td>
                  <td class="p-3 text-center">❌</td>
                  <td class="p-3 text-center">✅</td>
                </tr>
                <tr class="hover:bg-slate-50">
                  <td class="p-3 font-medium">Access section GradeSheets</td>
                  <td class="p-3 text-center">❌</td>
                  <td class="p-3 text-center">✅</td>
                </tr>
              </tbody>
            </table>
          </div>
          <ul class="mt-4 list-disc pl-5 text-sm space-y-2">
            <li><strong>Subject Teachers (Non-Advisers):</strong> Select their assigned subject classes, encode quarterly/term grades for students, and save entries to the database.</li>
            <li><strong>Class Advisers:</strong> Do everything a subject teacher does, plus manage their advisory section — reviewing compiled grades across subjects, finalizing records, syncing to Google Sheets, and accessing section GradeSheets.</li>
          </ul>
        </section>

        <!-- Section 2 -->
        <section>
          <h3 class="text-lg font-bold text-slate-800 mb-3 border-b pb-2">2. Subject Teachers — Encoding & Saving Grades</h3>
          <div class="space-y-4 text-sm">
            <div>
              <strong class="text-indigo-600 block mb-1">Step 1: Select Your Subject & Section</strong>
              <ul class="list-disc pl-5 space-y-1">
                <li>Log in with your registered account credentials.</li>
                <li>On your Teacher Dashboard, choose a class section and subject from the dropdown menus.</li>
                <li>The student roster for that subject class loads automatically.</li>
              </ul>
            </div>
            <div>
              <strong class="text-indigo-600 block mb-1">Step 2: Encode Student Grades</strong>
              <ul class="list-disc pl-5 space-y-1">
                <li>Enter quarterly/term grades directly into the grade input cells beside each student's name.</li>
                <li>Scores must follow the standard grading scale (60–100).</li>
              </ul>
            </div>
            <div>
              <strong class="text-indigo-600 block mb-1">Step 3: Save Entries</strong>
              <ul class="list-disc pl-5 space-y-1">
                <li>Click <strong>Save Grades</strong> in the toolbar.</li>
                <li>A confirmation banner verifies the grades were committed to the database.</li>
              </ul>
            </div>
            <div class="bg-blue-50 p-3 rounded text-blue-800 border border-blue-100">
              <strong>Note:</strong> You may update and resave grades anytime before the finalization deadline set by the class adviser or school administration.
            </div>
          </div>
        </section>

        <!-- Section 3 -->
        <section>
          <h3 class="text-lg font-bold text-slate-800 mb-3 border-b pb-2">3. Class Advisers — Advisory Section Management</h3>
          <div class="space-y-4 text-sm">
            <div>
              <strong class="text-slate-800 block mb-1">A. Managing Your Advisory Roster</strong>
              <ul class="list-disc pl-5 space-y-1">
                <li><strong>Add a student:</strong> Enter the 12-digit LRN, Full Name, Sex (M/F), and Birthday in the Add Student bar, then click Add +.</li>
                <li><strong>Edit a student:</strong> Click Edit next to their entry in the Male/Female table, update the fields inline, then click Save.</li>
                <li><strong>Delete a student:</strong> Click Del next to their record and confirm the prompt. This permanently removes them.</li>
              </ul>
            </div>
            <div>
              <strong class="text-slate-800 block mb-1">B. Reviewing & Finalizing Term Grades</strong>
              <ul class="list-disc pl-5 space-y-1">
                <li>Click <strong>View Term Grades Summary</strong> at the top right of your dashboard.</li>
                <li>This table compiles every subject teacher's submitted grades for each student in your section.</li>
                <li>Review for completeness and consistency.</li>
                <li>Once all subjects are submitted and verified, click <strong>Finalize Grades</strong> to lock the term record.</li>
              </ul>
            </div>
            <div>
              <strong class="text-slate-800 block mb-1">C. Syncing Data to Google Sheets</strong>
              <ul class="list-disc pl-5 space-y-1">
                <li>Click <strong>Sync to Google Sheets</strong> in your section toolbar.</li>
                <li>The system pushes your updated roster and grades to your mapped Google Spreadsheet.</li>
                <li>Wait for: <em>✅ Records successfully synced! (Timestamp).</em></li>
              </ul>
            </div>
            <div>
              <strong class="text-slate-800 block mb-1">D. Accessing Section GradeSheets</strong>
              <ul class="list-disc pl-5 space-y-1">
                <li>Click <strong>Go to GradeSheets</strong>.</li>
                <li>The system opens your section's mapped Google Sheet in a new tab.</li>
              </ul>
            </div>
          </div>
        </section>

        <!-- Section 4 -->
        <section>
          <h3 class="text-lg font-bold text-slate-800 mb-3 border-b pb-2">4. FAQ & Troubleshooting</h3>
          <div class="space-y-4 text-sm">
            <div>
              <strong class="block text-slate-800">I'm a Subject Teacher — why don't I see "Sync to Google Sheets" or "Go to GradeSheets"?</strong>
              <p class="mt-1 text-slate-600">These actions are restricted to Class Advisers.</p>
            </div>
            <div>
              <strong class="block text-slate-800">"Go to GradeSheets" shows "No mapped Google Sheet link found..."</strong>
              <p class="mt-1 text-slate-600">Your account isn't linked to a Google Sheet, or Row Level Security (RLS) is blocking retrieval. Contact your administrator to verify your email mapping in the <code>adviser_sheets</code> table.</p>
            </div>
            <div>
              <strong class="block text-slate-800">I can't edit grades from "View Term Grades Summary."</strong>
              <p class="mt-1 text-slate-600">Grades must be edited by the subject teacher who owns that subject, in their own Teacher Dashboard. Once saved, changes reflect automatically in the adviser's summary view.</p>
            </div>
            <div>
              <strong class="block text-slate-800">"Go to GradeSheets" isn't opening a new tab.</strong>
              <p class="mt-1 text-slate-600">Your browser may be blocking pop-ups. Click the pop-up blocker icon in your address bar and choose "Always allow pop-ups from this site."</p>
            </div>
          </div>
        </section>

      </div>
      
      <!-- Footer -->
      <div class="px-6 py-4 border-t border-slate-200 bg-slate-50 text-right">
        <button @click="$emit('close')" class="bg-indigo-600 hover:bg-indigo-700 text-white font-medium py-2 px-6 rounded-lg transition-colors shadow-sm">
          Acknowledge & Close
        </button>
      </div>

    </div>
  </div>
</template>
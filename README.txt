CreditCard - brought to you by Lot18 ( www.Lot18.com )

CreditCard entry and edit class with a really nice GUI based on the original design by Square (see a review of it here: http://functionsource.com/post/beautiful-forms).

This entry form has the following properties:

- accepts MC, Visa, AMEX, Discover,  and Diners Club (USA).

- uses Luhn code tests on the number so that minor entry errors are flagged - a user cannot proceed without entering a correct set of digits

- once four digits are entered, it creates correctly spaced placeholders so that a user knows exactly how many digits they need to enter

- after all digits are entered, it scrolls to a different view where the user sees the last four digits, and can enter the month/year and CCV

- for newly entered credit cards, the user can flick the view to see the full number, then back again to the expiration date and CCV

- the delete key properly skips white space

- in edit mode, the view accepts just the last 4 digits, allowing the user to update the expiration date and CCV (demo program does not exercise this)

- the current project uses a LED font found on the web; at one time the project worked with Courier but has not been tested with it lately.

- currently targetted to iOS 4.3, and uses ARC

This code will be used in an upcoming Lot18 iPhone app, and was developed by David Hoerl. It is made available with a BSD license:

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 * This file is part of CreditCard -- an iOS project that provides a smooth and elegant 
 * means to enter or edit credit cards. It was inspired by  a similar form created from 
 * scratch by Square (https://squareup.com/). To see this form in action visit:
 * 
 *   http://functionsource.com/post/beautiful-forms)
 *
 * Copyright 2012 Lot18 Holdings, Inc. All Rights Reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without modification, are
 * permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright notice, this list
 *       of conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY Lot18 Holdings ''AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL David Hoerl OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

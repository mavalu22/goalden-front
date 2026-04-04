/// Curated list of 40 motivational quotes for daily rotation.
const _quotes = [
  (
    text: 'The secret of getting ahead is getting started.',
    author: 'Mark Twain',
  ),
  (
    text:
        'It is not enough to be busy; so are the ants. The question is: what are we busy about?',
    author: 'Henry David Thoreau',
  ),
  (
    text: 'Either you run the day, or the day runs you.',
    author: 'Jim Rohn',
  ),
  (
    text:
        'The key is not to prioritize what\'s on your schedule, but to schedule your priorities.',
    author: 'Stephen Covey',
  ),
  (
    text:
        'You don\'t have to see the whole staircase, just take the first step.',
    author: 'Martin Luther King Jr.',
  ),
  (
    text: 'Action is the foundational key to all success.',
    author: 'Pablo Picasso',
  ),
  (
    text:
        'Amateurs sit and wait for inspiration, the rest of us just get up and go to work.',
    author: 'Stephen King',
  ),
  (
    text: 'Start where you are. Use what you have. Do what you can.',
    author: 'Arthur Ashe',
  ),
  (
    text: 'The way to get started is to quit talking and begin doing.',
    author: 'Walt Disney',
  ),
  (
    text: 'Small daily improvements over time lead to stunning results.',
    author: 'Robin Sharma',
  ),
  (
    text:
        'Discipline is choosing between what you want now and what you want most.',
    author: 'Abraham Lincoln',
  ),
  (
    text: 'Focus on being productive instead of busy.',
    author: 'Tim Ferriss',
  ),
  (
    text: 'The only way to do great work is to love what you do.',
    author: 'Steve Jobs',
  ),
  (
    text: 'What you do today can improve all your tomorrows.',
    author: 'Ralph Marston',
  ),
  (
    text: 'Don\'t count the days, make the days count.',
    author: 'Muhammad Ali',
  ),
  (
    text: 'Ordinary things consistently done produce extraordinary results.',
    author: 'Keith Cunningham',
  ),
  (
    text: 'Success is the sum of small efforts repeated day in and day out.',
    author: 'Robert Collier',
  ),
  (
    text: 'Your future is created by what you do today, not tomorrow.',
    author: 'Robert Kiyosaki',
  ),
  (
    text:
        'The best time to plant a tree was 20 years ago. The second best time is now.',
    author: 'Chinese Proverb',
  ),
  (
    text: 'It always seems impossible until it\'s done.',
    author: 'Nelson Mandela',
  ),
  (
    text: 'A goal without a plan is just a wish.',
    author: 'Antoine de Saint-Exupéry',
  ),
  (
    text:
        'Productivity is never an accident. It is always the result of a commitment to excellence.',
    author: 'Paul J. Meyer',
  ),
  (
    text: 'Do the hard jobs first. The easy jobs will take care of themselves.',
    author: 'Dale Carnegie',
  ),
  (
    text: 'The most effective way to do it is to do it.',
    author: 'Amelia Earhart',
  ),
  (
    text: 'You miss 100% of the shots you don\'t take.',
    author: 'Wayne Gretzky',
  ),
  (
    text:
        'Progress, not perfection, is what we should be asking of ourselves.',
    author: 'Julia Cameron',
  ),
  (
    text: 'Lost time is never found again.',
    author: 'Benjamin Franklin',
  ),
  (
    text: 'One day or day one. You decide.',
    author: 'Paulo Coelho',
  ),
  (
    text: 'Motivation is what gets you started. Habit is what keeps you going.',
    author: 'Jim Ryun',
  ),
  (
    text:
        'The only limit to our realization of tomorrow is our doubts of today.',
    author: 'Franklin D. Roosevelt',
  ),
  (
    text: 'Well done is better than well said.',
    author: 'Benjamin Franklin',
  ),
  (
    text:
        'If you spend too much time thinking about a thing, you\'ll never get it done.',
    author: 'Bruce Lee',
  ),
  (
    text:
        'I attribute my success to this: I never gave or took any excuse.',
    author: 'Florence Nightingale',
  ),
  (
    text:
        'You are never too old to set another goal or to dream a new dream.',
    author: 'C.S. Lewis',
  ),
  (
    text:
        'Be not afraid of going slowly; be afraid only of standing still.',
    author: 'Chinese Proverb',
  ),
  (
    text:
        'Great things are not done by impulse, but by a series of small things brought together.',
    author: 'Vincent van Gogh',
  ),
  (
    text:
        'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
    author: 'Aristotle',
  ),
  (
    text: 'The future depends on what you do today.',
    author: 'Mahatma Gandhi',
  ),
  (
    text: 'Simplicity is the ultimate sophistication.',
    author: 'Leonardo da Vinci',
  ),
  (
    text: 'Do what you can, with what you have, where you are.',
    author: 'Theodore Roosevelt',
  ),
];

/// Returns the quote to display today, cycling deterministically through the
/// list based on the local day-of-year (same quote for all users on the same
/// calendar day, repeats every 40 days).
({String text, String author}) getTodayQuote() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  return _quotes[dayOfYear % _quotes.length];
}

'reach 0.1';
'use strict';

export const main = Reach.App(() => {
  const Creator = Participant('Creator', {
    // Specify the Creator's interact interface here
  });
  const Owner   = Participant('Owner', {
    // Specify the Owner's interact interface here
  });
  init();
  // write your program here

});

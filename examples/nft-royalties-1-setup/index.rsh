'reach 0.1';

export const main = Reach.App(() => {
  const Creator = Participant('Creator', {
    // Specify the Creator's interact interface here
  });
  const Owner   = ParticipantClass('Owner', {
    // Specify the Owner's interact interface here
  });

  init();
  // write your program here

});

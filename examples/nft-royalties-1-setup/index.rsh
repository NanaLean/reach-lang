'reach 0.1';

export const main = Reach.App(() => {
  const Alice = Participant('Alice', {
    // Specify the Alice's interact interface here
  });
  const Bob   = Participant('Bob', {
    // Specify the Bob's interact interface here
  });

  init();
  // write your program here

});
